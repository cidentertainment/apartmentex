defmodule Mix.Tasks.Apartmentex.Migrate.Tenants do
  use Mix.Task
  import Mix.Ecto
  import Ecto.Query, only: [from: 2]

  @schema_prefix Application.get_env(:apartmentex, :schema_prefix) || "tenant_"
  @tenant_migration_folder "priv/repo/tenant_migrations"

  @moduledoc """
  Migrate all tenants

  ##Usage

    mix apartmentex.migrate.tenants

  """

  def run(args) do
    repos = parse_repo(args)

    {opts, _, _} = OptionParser.parse args,
      switches: [all: :boolean, step: :integer, to: :integer, quiet: :boolean,
                 prefix: :string, pool_size: :integer],
      aliases: [n: :step, v: :to]

    opts =
      if opts[:to] || opts[:step] || opts[:all],
        do: opts,
        else: Keyword.put(opts, :all, true)

    opts =
      if opts[:quiet],
        do: Keyword.put(opts, :log, false),
        else: opts

    Enum.each repos, fn repo ->
      ensure_repo(repo, args)
      {:ok, pid} = ensure_started(repo)

      tenants = repo.all(from t in "tenants", select: t.id)
      results = Enum.map tenants, fn tenant, acc -> do_migrate(repo, opts, tenant) end

      pid && ensure_stopped(repo, pid)

      unless opts[:quiet] do
        Mix.shell.info "migrated #{Enum.count(results, fn r -> is_integer(r) end)} tenant successfully with #{Enum.count(results, fn r -> is_atom(r) end)} failures on repo #{inspect repo}"
      end
    end
  end

  def do_migrate(repo, opts, tenant) do
    Ecto.Migrator.run(repo, @tenant_migration_folder, :up, Keyword.put(opts, :prefix, String.to_atom(build_prefix(tenant))))
  rescue Ecto.MigrationError ->
    :error
  end

  def build_prefix(tenant) do
    @schema_prefix <> Integer.to_string(tenant.id)
  end
end