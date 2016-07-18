defmodule Mix.Tasks.Apartmentex.Migrate.TenantsTest do
  use ExUnit.Case

  alias Mix.Tasks.Apartmentex.Migrate.Tenants, as: MigrateTenants
  alias Apartmentex.TestPostgresRepo

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestPostgresRepo)
    :ok
  end

  test 'runs a series of tenant migrations' do
    Apartmentex.new_tenant(TestPostgresRepo, 1)
    Apartmentex.new_tenant(TestPostgresRepo, 2)
    MigrateTenants.run ["-r", to_string(Apartmentex.TestPostgresRepo)]
    assert_received {:mix_shell, :info, ["foo"]}
  end
end