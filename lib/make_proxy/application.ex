defmodule MakeProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @worker System.fetch_env!("WORKER_TYPE") |> String.to_atom()
  @protocol %{make_proxy_client: :mp_client_worker, make_proxy_server: :mp_server_worker}
  @port_def %{make_proxy_client: :client_port, make_proxy_server: :server_port}
  @port Application.compile_env!(:make_proxy, @port_def[@worker])

  @impl true
  def start(_type, _args) do
    ranch_listener =
      :ranch.child_spec(
        @worker,
        :ranch_tcp,
        transport_opts(),
        @protocol[@worker],
        []
      )

    opts = [strategy: :one_for_one, name: MakeProxy.Supervisor]
    Supervisor.start_link([ranch_listener], opts)
  end

  defp transport_opts() do
    %{
      max_connections: get_env_integer("MKP_MAX_CONNECTIONS", "100"),
      num_acceptors: get_env_integer("MKP_MAX_ACCEPTORS", "10"),
      socket_opts: [port: @port]
    }
  end

  defp get_env_integer(key, default) do
    System.get_env(key, default) |> String.to_integer()
  end
end
