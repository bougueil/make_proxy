defmodule MakeProxy.Worker.Client do
  @moduledoc """
  implements `:ranch_protocol` for transport @transport
  """
  use GenServer

  @behaviour :ranch_protocol

  alias MakeProxy.Client
  alias MakeProxy.Crypto

  @transport :ranch_tcp

  @impl true
  def start_link(ref, @transport, key: key), do: GenServer.start_link(__MODULE__, [ref, key])

  @impl true
  def init([ref, key]) do
    # ranch values, see Transport:messages() :
    # OK: :tcp, Closed: :tcp_closed, Error: :tcp_error, Passive: :tcp_passive
    state = %Client{
      key: key,
      ref: ref,
      socket: nil,
      buffer: "",
      keep_alive: false
    }

    {:ok, state, {:continue, :wait_control}}
  end

  @impl true
  def handle_continue(:wait_control, %{ref: ref} = state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = @transport.setopts(socket, active: :once, packet: :raw)
    {:noreply, %{state | socket: socket}}
  end

  @impl true
  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, protocol: nil} = state
      ) do
    with {:ok, protocol_handler} <- detect_protocol(data),
         protocol <- &protocol_handler.request/2,
         state1 <- %{state | protocol: protocol},
         {:ok, state2} <- protocol.(data, state1),
         :ok <- @transport.setopts(socket, active: :once) do
      {:noreply, state2}
    else
      error ->
        {:stop, error, state}
    end
  end

  def handle_info(
        {:tcp, socket, data},
        %{socket: socket, protocol: protocol} = state
      ) do
    with {:ok, state1} <- protocol.(data, state),
         :ok <- @transport.setopts(socket, active: :once) do
      {:noreply, state1}
    else
      error ->
        {:stop, error, state}
    end
  end

  def handle_info({:tcp, remote, data}, %{key: key, socket: socket, remote: remote} = state) do
    with {:ok, data} <- Crypto.decrypt(key, data),
         :ok <- @transport.send(socket, data),
         :ok <- :inet.setopts(remote, active: :once) do
      {:noreply, state}
    else
      error ->
        {:stop, error, state}
    end
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}

  def handle_info({:tcp_error, _, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info(:timeout, state), do: {:stop, :normal, state}

  @impl true
  def terminate(_reason, %{socket: socket, remote: remote}) do
    is_port(socket) && @transport.close(socket)
    is_port(remote) && :gen_tcp.close(remote)
  end

  defp detect_protocol(<<head, _::binary>>) do
    protocols = [Client.Http, Client.Socks]
    do_detect_protocol(head, protocols)
  end

  defp detect_protocol(_), do: {:error, :invalid_data}

  defp do_detect_protocol(head, [protocol | rest]) do
    if protocol.detect_head(head) do
      {:ok, protocol}
    else
      do_detect_protocol(head, rest)
    end
  end

  defp do_detect_protocol(_, []), do: {:error, :no_protocol_handler}
end
