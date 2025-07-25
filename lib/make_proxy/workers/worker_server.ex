defmodule MakeProxy.Worker.Server do
  @moduledoc """
  implements `:ranch_protocol` for transport @transport
  """

  use GenServer
  @behaviour :ranch_protocol
  @timeout :timer.minutes(10)
  @transport :ranch_tcp
  alias MakeProxy.Crypto

  @impl true
  def start_link(ref, @transport, key: key), do: GenServer.start_link(__MODULE__, [ref, key])

  @impl true
  def init([ref, key]) do
    state = %{
      key: key,
      ref: ref,
      remote: nil,
      socket: nil
    }

    {:ok, state, {:continue, :wait_control}}
  end

  @impl true
  def handle_continue(:wait_control, %{ref: ref} = state) do
    {:ok, socket} = :ranch.handshake(ref)
    :ok = @transport.setopts(socket, active: :once, packet: 4)
    {:noreply, %{state | socket: socket}}
  end

  @impl true
  # first message from client
  def handle_info(
        {:tcp, socket, request},
        %{key: key, socket: socket, remote: nil} = state
      ) do
    with {:ok, remote} <- connect_to_remote(request, key),
         :ok <- @transport.setopts(socket, active: :once) do
      {:noreply, %{state | remote: remote}, @timeout}
    else
      _error ->
        {:stop, :normal, state}
    end
  end

  # recv from client, then send to server
  def handle_info(
        {:tcp, socket, request},
        %{key: key, socket: socket, remote: remote} = state
      ) do
    with {:ok, request} <- Crypto.decrypt(key, request),
         :ok <- :gen_tcp.send(remote, request),
         :ok <- @transport.setopts(socket, active: :once) do
      {:noreply, state, @timeout}
    else
      error ->
        {:stop, error, state}
    end
  end

  # recv from server, and send back to client
  def handle_info({:tcp, remote, resp}, %{key: key, socket: client, remote: remote} = state) do
    with :ok <- @transport.send(client, Crypto.encrypt(key, resp)),
         :ok <- :inet.setopts(remote, active: :once) do
      {:noreply, state, @timeout}
    else
      _error ->
        {:stop, :normal, state}
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
