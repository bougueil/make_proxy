defmodule MakeProxy.Worker.Client do
  @moduledoc """
      client (near browser) worker
  """
  use ThousandIsland.Handler

  alias MakeProxy.SocksRequestHandler
  alias MakeProxy.HttpRequestHandler
  alias MakeProxy.Crypto
  alias MakeProxy.WorkerState

  @telemetry_event [:make_proxy, :connection, :client]

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    :ok = ThousandIsland.Socket.setopts(socket, packet: :raw)
    {:continue, Map.merge(%WorkerState{}, state)}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, %{handler: nil} = state) do
    with {:ok, protocol_handler} <- detect_handler(data),
         handler <- &protocol_handler.request/3,
         state1 <- %{state | handler: handler},
         {:ok, state2} <- handler.(data, socket, state1) do
      {:continue, state2}
    else
      {:error, error} when error in [:econnrefused, :enetunreach, :ehostunreach] ->
        {:close, state}

      error ->
        :telemetry.execute(@telemetry_event, %{}, %{
          error: error,
          remote_address: socket.span.start_metadata.remote_address,
          ctx: "detect_handler"
        })

        {:error, "#{inspect(error)}", state}
    end
  end

  def handle_data(data, socket, %{handler: handler} = state) do
    case handler.(data, socket, state) do
      {:ok, state1} ->
        {:continue, state1}

      error ->
        :telemetry.execute(@telemetry_event, %{}, %{
          error: error,
          remote_address: socket.span.start_metadata.remote_address,
          ctx: "do handler"
        })

        {:error, "#{inspect(error)}", state}
    end
  end

  def handle_info({:tcp, remote, data}, {socket, %{key: key, remote: remote} = _state} = so_st) do
    with {:ok, data} <- Crypto.decrypt(key, data),
         :ok <- ThousandIsland.Socket.send(socket, data),
         :ok <- :inet.setopts(remote, active: :once) do
      {:noreply, so_st}
    else
      {:error, error} when error in [:closed, :timeout, :einval] ->
        {:stop, {:shutdown, :peer_closed}, so_st}

      error ->
        :telemetry.execute(@telemetry_event, %{}, %{
          error: error,
          remote_address: socket.span.start_metadata.remote_address,
          ctx: "decrypt"
        })

        {:error, "#{inspect(error)}", so_st}
    end
  end

  def handle_info({:tcp_closed, remote}, {_, %{remote: remote}} = so_st),
    do: {:stop, {:shutdown, :peer_closed}, so_st}

  def handle_info(msg, {socket, _} = so_st) do
    :telemetry.execute(@telemetry_event, %{}, %{
      error: msg,
      remote_address: socket.span.start_metadata.remote_address,
      ctx: "handle_info_unknown msg"
    })

    {:stop, "#{inspect(msg)}", so_st}
  end

  @impl ThousandIsland.Handler
  def handle_close(_socket, %{remote: remote}) do
    _ = is_port(remote) && :gen_tcp.close(remote)
  end

  defp detect_handler(<<head, _::binary>>) do
    handlers = [HttpRequestHandler, SocksRequestHandler]
    do_detect_handler(head, handlers)
  end

  defp detect_handler(_), do: {:error, :invalid_data}

  defp do_detect_handler(head, [handler | rest]) do
    if handler.detect_head(head) do
      {:ok, handler}
    else
      do_detect_handler(head, rest)
    end
  end

  defp do_detect_handler(_, []), do: {:error, :no_protocol_handler}
end
