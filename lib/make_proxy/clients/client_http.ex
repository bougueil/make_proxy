defmodule MakeProxy.Client.Http do
  @behaviour MakeProxy.Client.Protocol

  @moduledoc """
      Protocol for HTTP
  """

  @transport ThousandIsland.Socket

  alias MakeProxy.Crypto
  alias MakeProxy.HttpRequest
  alias MakeProxy.Utils
  alias MakeProxy.WorkerState

  # GET, POST PUT, HEAD, DELETE, TRACE, CONNECT, OPTIONS
  @http_method_head ~c"GPHDTCO"

  @impl MakeProxy.Client.Protocol
  def detect_head(h), do: h in @http_method_head

  @impl MakeProxy.Client.Protocol
  def request(data, socket, %WorkerState{remote: nil, buffer: buffer} = state) do
    data1 = <<buffer::binary, data::binary>>
    {data2, req} = parse_http_request(data1)

    case req.status do
      :done ->
        do_communication(data2, socket, req, state)

      :error ->
        {:error, :parse_http_request_error}

      :more ->
        {:ok, %{state | buffer: data1}}
    end
  end

  def request(data, socket, %WorkerState{remote: remote, keep_alive: false} = state) do
    :gen_tcp.close(remote)
    request(data, socket, %{state | remote: nil})
  end

  def request(data, _socket, %WorkerState{key: key, remote: remote, keep_alive: true} = state) do
    _ = :gen_tcp.send(remote, Crypto.encrypt(key, data))
    {:ok, state}
  end

  # -spec do_communication(binary(), #http_request{}, #client{}) ->
  #     {ok, #client{}} |
  #     {error, term()}.
  defp do_communication(
         data,
         socket,
         %{host: host, port: port, next_data: next_data} = req,
         %{key: key} = state
       ) do
    case Utils.connect_to_remote() do
      {:ok, remote} ->
        :ok = :gen_tcp.send(remote, Crypto.encrypt(key, :erlang.term_to_binary({host, port})))
        state1 = %{state | remote: remote, buffer: next_data}

        if req.method == "CONNECT" do
          _ = @transport.send(socket, "HTTP/1.1 200 OK\r\n\r\n")
          {:ok, %{state1 | keep_alive: true}}
        else
          this_data = :binary.part(data, 0, byte_size(data) - byte_size(next_data))
          :ok = :gen_tcp.send(remote, Crypto.encrypt(key, this_data))
          {:ok, state1}
        end

      {:error, _reason} = err ->
        err
    end
  end

  def parse_http_request(data), do: parse_http_request(data, %HttpRequest{})

  defp parse_http_request(data, req) do
    case :binary.split(data, "\r\n") do
      [data] ->
        req1 = %{req | status: :more}
        {data, req1}

      [request_line, headers] ->
        {request_line1, req1} = parse_request_line(request_line, req)

        req2 =
          if req1.method == "CONNECT" do
            %{req1 | status: :done}
          else
            do_parse(:erlang.decode_packet(:httph_bin, headers, []), req1)
          end

        data1 = IO.iodata_to_binary([request_line1, "\r\n", headers])
        {data1, req2}
    end
  end

  defp do_parse({:error, _}, req), do: %{req | status: :error}

  defp do_parse({:more, _}, req), do: %{req | status: :more}

  defp do_parse({:ok, :http_eoh, rest}, %{content_length: 0} = req),
    do: %{req | status: :done, next_data: rest}

  defp do_parse(
         {:ok, :http_eoh, rest},
         %{content_length: content_length, current_length: content_length} = req
       ),
       do: %{req | status: :done, next_data: rest}

  defp do_parse(
         {:ok, :http_eoh, rest},
         %{content_length: content_length, current_length: current_length} = req
       ) do
    more_need_length = content_length - current_length
    rest_len = byte_size(rest)

    if rest_len >= more_need_length do
      <<_body::bytes-size(more_need_length), next_data::binary>> = rest

      %{
        req
        | status: :done,
          current_length: current_length + more_need_length,
          next_data: next_data
      }
    else
      %{req | status: :more, current_length: current_length + rest_len}
    end
  end

  defp do_parse({:ok, {:http_header, _num, :"Content-Length", _, value}, rest}, req) do
    req1 = %{req | content_length: String.to_integer(value)}
    do_parse(:erlang.decode_packet(:httph_bin, rest, []), req1)
  end

  defp do_parse({:ok, {:http_header, _, _, _, _}, rest}, req),
    do: do_parse(:erlang.decode_packet(:httph_bin, rest, []), req)

  defp parse_request_line(request_line, req) do
    [method, url, version] = String.split(request_line, " ")

    %{path: path, host: host, port: port} =
      Map.merge(
        %{port: 80},
        :uri_string.parse(
          case url do
            <<"http://", _::binary>> ->
              url

            _ ->
              <<"http://", url::binary>>
          end
        )
      )

    path1 =
      case path do
        <<>> -> "/"
        _ -> path
      end

    {
      [method, " ", path1, " ", version],
      %{req | method: method, host: resolve_host(to_charlist(host)), port: port}
    }
  end

  defp resolve_host(host) do
    case :inet.parse_address(host) do
      {:ok, addr} -> addr
      _ -> host
    end
  end
end
