defmodule Bank.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Bank.Bucket.Supervisor, []),
      supervisor(BankWeb.Endpoint, []),
      # Start your own worker by calling: Bank.Worker.start_link(arg1, arg2, arg3)
      # worker(Bank.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options]
    opts = [strategy: :one_for_one, name: Bank.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BankWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
