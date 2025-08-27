defmodule MakeProxy.Worker.Server do
  @moduledoc """
      server worker
  """
  use ThousandIsland.Handler

  alias MakeProxy.Crypto
  @timeout :timer.minutes(10)
  @telemetry_event [:make_proxy, :connection, :server]

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    :ok = ThousandIsland.Socket.setopts(socket, packet: 4)
    {:continue, state, socket.read_timeout}
  end

  @impl ThousandIsland.Handler
  # first message from client
  def handle_data(request, socket, %{key: key, remote: nil} = state) do
    case connect_to_remote(request, key) do
      {:ok, remote} ->
        {:continue, %{state | remote: remote}, @timeout}

      {:error, {:connect_failure, _ip, _}} ->
        {:close, state}

      error ->
        :telemetry.execute(@telemetry_event, %{}, %{
          error: error,
          remote_address: socket.span.start_metadata.remote_address,
          ctx: "connect_to_remote"
        })

        {:close, state}
    end
  end

  # recv from client, then send to server
  def handle_data(request, socket, %{key: key, remote: remote} = state) do
    with {:ok, request} <- Crypto.decrypt(key, request),
         :ok <- :gen_tcp.send(remote, request) do
      {:continue, state, @timeout}
    else
      {:error, error} when error in [:closed] ->
        {:close, state}

      error ->
        :telemetry.execute(@telemetry_event, %{}, %{
          error: error,
          remote_address: socket.span.start_metadata.remote_address,
          ctx: "connect_2"
        })

        {:error, "#{inspect(error)}", state}
    end
  end

  def handle_error(reason, socket, _state) do
    :telemetry.execute(@telemetry_event, %{}, %{
      error: reason,
      remote_address: socket.span.start_metadata.remote_address,
      ctx: "handle_error"
    })
  end

  # recv from server, and send back to client
  def handle_info({:tcp, remote, resp}, so_st = {socket, %{key: key, remote: remote} = _state}) do
    with :ok <- ThousandIsland.Socket.send(socket, Crypto.encrypt(key, resp)),
         :ok <- :inet.setopts(remote, active: :once) do
      {:noreply, so_st, @timeout}
    else
      _ ->
        {:stop, {:shutdown, :peer_closed}, so_st}
    end
  end

  def handle_info({:tcp_closed, remote}, so_st = {_, %{remote: remote}}) do
    {:stop, {:shutdown, :peer_closed}, so_st}
  end

  def handle_info(msg, so_st = {socket, _}) do
    :telemetry.execute(@telemetry_event, %{}, %{
      error: msg,
      remote_address: socket.span.start_metadata.remote_address,
      ctx: "handle_info_unknown"
    })

    {:stop, {:shutdown, :peer_closed}, so_st}
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, %{remote: remote}) do
    _ = is_port(remote) && :gen_tcp.close(remote)
  end

  defp connect_to_remote(data, key) do
    with(
      {:ok, data} <- Crypto.decrypt(key, data),
      {addr, port} <- :erlang.binary_to_term(data)
    ) do
      connect_target(addr, port)
    end
  end

  defp connect_target(addr, port), do: connect_target(addr, port, 2)

  defp connect_target(addr, port, 0), do: {:error, {:connect_failure, addr, port}}

  @connect_opts [:binary, active: :once]

  defp connect_target(addr, port, retry_times) do
    case :gen_tcp.connect(addr, port, @connect_opts, 5000) do
      {:ok, _target_socket} = res ->
        res

      {:error, _error} ->
        connect_target(addr, port, retry_times - 1)
    end
  end
end
