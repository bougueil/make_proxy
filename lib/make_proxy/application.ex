defmodule MakeProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias MakeProxy.WorkerState

  @worker_type Application.compile_env!(:make_proxy, :worker)
  @port Application.compile_env!(:make_proxy, [@worker_type, :port])
  @worker Application.compile_env!(:make_proxy, [@worker_type, :worker])
  @default_max_connections "100"
  @default_max_acceptors "10"
  @transport_options (if @worker_type == :make_proxy_client do
                        {:ok, hostname} = :inet.gethostname()
                        {:ok, hostname_ip} = :inet.getaddr(hostname, :inet)
                        [ip: hostname_ip]
                      else
                        []
                      end)

  @impl true
  def start(_type, _args) do
    children = [
      {
        ThousandIsland,
        port: @port,
        handler_module: @worker,
        handler_options: %WorkerState{key: Application.fetch_env!(:make_proxy, :key)},
        num_connections: get_env_integer("MKP_MAX_CONNECTIONS", @default_max_connections),
        num_acceptors: get_env_integer("MKP_MAX_ACCEPTORS", @default_max_acceptors),
        transport_options: @transport_options
      }
    ]

    :ok = MakeProxy.Logger.attach_events()

    opts = [strategy: :one_for_one, name: MakeProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_env_integer(key, default), do: System.get_env(key, default) |> String.to_integer()
end
