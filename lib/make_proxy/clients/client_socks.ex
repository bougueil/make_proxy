defmodule MakeProxy.Client.Socks do
  @behaviour MakeProxy.Client.Protocol

  @moduledoc """
  Protocol for Socks :
  - http://www.openssh.com/txt/socks4.protocol
  - https://www.ietf.org/rfc/rfc1928.tx
  """
  @transport :ranch_tcp

  alias MakeProxy.Client
  alias MakeProxy.Crypto
  alias MakeProxy.Utils

  @impl MakeProxy.Client.Protocol
  def detect_head(version), do: version in [4, 5]

  @impl MakeProxy.Client.Protocol
  def request(
        data,
        %Client{key: key, socket: socket, remote: nil, buffer: buffer} =
          state
      ) do
    data1 = <<buffer::binary, data::binary>>

    with {:ok, target, body, response} <- find_target(data1),
         {:ok, remote} <- Utils.connect_to_remote(),
         :ok <- :gen_tcp.send(remote, Crypto.encrypt(key, :erlang.term_to_binary(target))),
         _ <- if(body == "", do: :ok, else: :gen_tcp.send(remote, Crypto.encrypt(key, body))),
         :ok <- @transport.send(socket, response) do
      {:ok, %{state | remote: remote}}
    else
      :more ->
        # reply success info
        if(buffer != "", do: :ok, else: :ok = @transport.send(socket, <<5, 0>>))
        {:ok, %{state | buffer: data1}}

      {:error, _reason} = err ->
        err
    end
  end

  def request(data, %Client{key: key, remote: remote} = state) do
    :ok = :gen_tcp.send(remote, Crypto.encrypt(key, data))
    {:ok, state}
  end

  #  http://www.openssh.com/txt/socks4.protocol
  # -spec find_target(binary()) ->
  #     {ok, mp_target(), binary(), binary()} |
  #     {error, term()} |
  #     more.
  defp find_target(<<4, _cd, port::16, a1, a2, a3, a4, rest::binary>>) do
    case split_socks4_data(rest) do
      {:ok, _user_id, body} ->
        target = {{a1, a2, a3, a4}, port}
        response = <<0, 90, port::16, a1, a2, a3, a4>>
        {:ok, target, body, response}

      {:error, _reason} = err ->
        err

      :more ->
        :more
    end
  end

  defp find_target(<<4, _rest::binary>>), do: :more

  # https://www.ietf.org/rfc/rfc1928.txt
  defp find_target(<<5, n, _methods::bytes-size(n), 5, _cmd, _rsv, atype, rest::binary>>) do
    case split_socks5_data(atype, rest) do
      {:ok, target, body} ->
        response = <<5, 0, 0, 1, <<0, 0, 0, 0>>::binary, 0::16>>
        {:ok, target, body, response}

      {:error, _reason} = err ->
        err

      :more ->
        :more
    end
  end

  defp find_target(<<5, _rest::binary>>), do: :more

  defp find_target(_), do: {:error, :invalid_data}

  # -spec  defp split_socks5_data(integer(), binary()) ->
  #     {ok, mp_target(), binary()} |
  #     {error, term()} |
  #     more.
  defp split_socks5_data(1, <<a1, a2, a3, a4, port::16, body::binary>>) do
    target = {{a1, a2, a3, a4}, port}
    {:ok, target, body}
  end

  defp split_socks5_data(1, _), do: :more

  defp split_socks5_data(3, <<len, domain::bytes-size(len), port::16, body::binary>>) do
    target = {to_charlist(domain), port}
    {:ok, target, body}
  end

  defp split_socks5_data(3, _), do: :more

  defp split_socks5_data(4, <<address::bytes-size(16), port::16, body::binary>>) do
    target = {List.to_tuple(to_charlist(address)), port}
    {:ok, target, body}
  end

  defp split_socks5_data(4, _), do: :more

  defp split_socks5_data(_, _), do: {:error, :invalid_data}

  # -spec  defp split_socks4_data(binary()) ->
  #     {ok, string(), binary()} |
  #     {error, term()} |
  #     more.
  def split_socks4_data(data), do: split_socks4_data(data, [])

  defp split_socks4_data("", _userID), do: :more

  defp split_socks4_data(<<0, body::binary>>, userID) do
    id = :lists.flatten(:lists.join("", :lists.reverse(userID)))
    {:ok, id, body}
  end

  defp split_socks4_data(<<part, rest::binary>>, userID) do
    if length(userID) > 1024 do
      {:error, :userid_too_long}
    else
      split_socks4_data(rest, [Integer.to_charlist(part) | userID])
    end
  end
end
