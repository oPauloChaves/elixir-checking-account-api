defmodule Bank.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Bank.Bucket.{Bucket, Registry}
  alias Bank.Accounts.Operation

  @bucket_name "operations"
  @debit_types ["purchase", "withdrawal", "debits"]
  @credit_types ["deposit", "salary", "credits"]

  def get_operations_by_account(number) do
    {:ok, bucket} = Registry.lookup(Registry, @bucket_name)
    case Bucket.get(bucket, number) do
      nil -> []
      operations -> operations
    end
  end

  def create_operation(number, attrs \\ %Operation{}) do
    {:ok, bucket} = Registry.lookup(Registry, @bucket_name)
    Bucket.put(bucket, number, attrs)
    {:ok, attrs}
  end

  @doc """
  Returns the balance of a given account. The balance is the sum of all
  operations until today. Debit operations are considered negative values
  """
  def get_balance(number) do
    {:ok, bucket} = Registry.lookup(Registry, @bucket_name)

    Bucket.get(bucket, number)
    |> sort_operations_by_date
    |> filter_operations_till_now
    |> calculate_balance 
  end
  
  @doc """
  Returns the balance given a list of operations of a given account
  """
  def calculate_balance(operations) do
    operations
    |> Enum.reduce(0, fn(%{type: type, amount: amount}, acc) -> 
      cond do
        Enum.member?(@credit_types, type) -> acc + amount
        Enum.member?(@debit_types, type) -> acc - amount
        true -> acc
      end
    end)
  end

  # Returns a list containing all operations of a given account where the date is <= today 
  defp filter_operations_till_now(operations) do
    now = NaiveDateTime.utc_now

    operations
    |> Enum.filter(fn op -> 
      NaiveDateTime.compare(op.date, now) == :lt
    end)
  end

  @doc """
  Returns a list of operations sorted by date (ASC)

  ## Examples

      iex> operations = [%{date: ~N[2017-01-01 10:20:19]}, %{date: ~N[2017-01-01 10:20:18]}, %{date: ~N[2017-01-01 10:19:00]}]
      iex> Bank.Accounts.sort_operations_by_date(operations)
      [%{date: ~N[2017-01-01 10:19:00]}, %{date: ~N[2017-01-01 10:20:18]}, %{date: ~N[2017-01-01 10:20:19]}]

  """
  def sort_operations_by_date(operations) do
    operations
    |> Enum.sort(fn(%{date: date1}, %{date: date2}) ->
      NaiveDateTime.compare(date1, date2) == :lt
    end) 
  end

  @doc """
  Get the bank state of a given account of a period of dates 
  """
  def get_statement(number, start_date, end_date \\ NaiveDateTime.utc_now) do
    {:ok, bucket} = Registry.lookup(Registry, @bucket_name)
    Bucket.get(bucket, number)
    |> sort_operations_by_date
    |> filter_by_period(start_date, end_date)
    |> group_by_date
    |> calc_balance_by_date
  end

  @doc """
  Returns a lists containing the period of debts of a given account if applicable
  """
  def get_periods_of_debt(number) do
    {:ok, bucket} = Registry.lookup(Registry, @bucket_name)
    Bucket.get(bucket, number)
    |> sort_operations_by_date
    |> group_by_date
    |> calc_balance_by_date
    |> process_periods_of_debt
  end

  defp process_periods_of_debt(operations_by_date) do
    period_debts =
      operations_by_date
      |> Enum.reduce([], fn(%{balance: balance, date: date}, state) -> 
        cond do
          balance < 0 ->
            if length(state) > 0 do
              previous = state |> List.last
              if previous |> Map.has_key?(:end) == false do
                previous = Map.update(previous, :principal, balance, fn(_) -> balance end)
                List.replace_at(state, -1, previous)
              else
                state ++ [%{principal: balance, start: date}]
              end
            else
              state ++ [%{principal: balance, start: date}]
            end
          balance >= 0 ->
            if length(state) > 0 do
              previous = state |> List.last 
              if previous |> Map.has_key?(:end) == false do
                if Date.compare(date, Date.utc_today) != :gt do
                  previous = Map.update(previous, :end, Date.add(date, -1), &(&1))
                  List.replace_at(state, -1, previous)
                else
                  state
                end
              else
                state
              end
            else
              state
            end
        end  
      end)
    period_debts
  end

  @doc """
  Return a list where each element is a map containing `date`, `operations` and `balance` accumulated until `date`
  
  `[%{date: ~D[2017-08-01], operations: [], balance: 100}]`

  `ops_by_date` is a map of operations grouped by date in which map key is a `date` and `value`
  is a list of operations.
  """
  def calc_balance_by_date(ops_by_date) do
    ops_by_date
    |> Enum.reduce([], fn({date, operations}, current_state) -> 
      acc_balance = case List.last(current_state) do
        nil -> 0
        last -> last.balance
      end
      day_balance = calculate_balance(operations)

      current_state ++ [%{
        date: date,
        operations: operations,
        balance: acc_balance + day_balance,
      }]
    end)
  end

  @doc """
  Returns a list of operations filtered by a period of dates. This list includes
  all operations in which its `date` >= `start_date` and <= `end_date`

  ## Examples

      iex> operations = [%{date: ~N[2017-01-01 10:20:19]}, %{date: ~N[2017-01-02 00:00:00]}, %{date: ~N[2017-01-01 23:59:59]}]
      iex> Bank.Accounts.filter_by_period(operations, ~N[2017-01-01 00:00:00], ~N[2017-01-01 23:59:59])
      [%{date: ~N[2017-01-01 10:20:19]}, %{date: ~N[2017-01-01 23:59:59]}]

  """
  def filter_by_period(operations, start_date, end_date) do
    operations
    |> Enum.filter(fn %{date: date} -> 
      NaiveDateTime.compare(date, start_date) != :lt and NaiveDateTime.compare(date, end_date) != :gt
    end)
  end
  
  @doc """
  Returns a map containing the operations grouped by date

  ## Examples

      iex> operations = [%{date: ~N[2017-01-01 10:20:19]}, %{date: ~N[2017-01-02 00:00:00]}, %{date: ~N[2017-01-01 22:00:00]}]
      iex> Bank.Accounts.group_by_date(operations)
      %{~D[2017-01-01] => [%{date: ~N[2017-01-01 10:20:19]}, %{date: ~N[2017-01-01 22:00:00]}], ~D[2017-01-02] => [%{date: ~N[2017-01-02 00:00:00]}]}

  """
  def group_by_date(operations) do
    operations
    |> Enum.reduce(%{}, fn operation, map -> 
      Map.update(map, NaiveDateTime.to_date(operation.date), [operation], &(&1 ++ [operation]) )
    end)
  end
end
