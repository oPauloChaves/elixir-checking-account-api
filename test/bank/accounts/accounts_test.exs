defmodule Bank.Accounts.AccountsTest do
  use ExUnit.Case, async: true
  doctest Bank.Accounts

  alias Bank.Bucket.{Registry}
  alias Bank.Accounts
  alias Bank.Accounts.Operation

  @operations [
    %Operation{number: "123", amount: 500, description: "some operation", type: "deposit", date: ~N[2017-08-01 00:00:00]},
    %Operation{number: "123", amount: 1000, description: "some operation", type: "deposit", date: ~N[2017-08-02 00:00:00]},
    %Operation{number: "123", amount: 150, description: "some operation", type: "purchase", date: ~N[2017-08-01 00:00:00]},
    %Operation{number: "123", amount: 35, description: "some operation", type: "purchase", date: ~N[2017-08-02 00:00:00]},
    %Operation{number: "123", amount: 220, description: "some operation", type: "withdrawal", date: ~N[2017-08-05 00:00:00]},
    %Operation{number: "123", amount: 390, description: "some operation", type: "withdrawal", date: NaiveDateTime.utc_now}
  ]

  @number "123"

  setup do
    # ensure a clean state for each test
    Application.stop :bank
    Application.start :bank
  end

  setup do
    # creates a bucket "operations" a registers it in the GenServer
    Registry.create(Registry, "operations")
  end

  test "stores an operation an retrieves by account number" do
    assert Accounts.get_operations_by_account(@number) == []
  
    assert {:ok, %Operation{} = operation} = Accounts.create_operation(@number, List.first(@operations))

    assert Accounts.get_operations_by_account(@number) == [operation]
  end

  test "get the current balance of a given account" do
    Enum.each(@operations, &Accounts.create_operation(@number, &1))
    assert length(Accounts.get_operations_by_account(@number)) == 6

    assert Accounts.get_balance(@number) == 705
  end
end