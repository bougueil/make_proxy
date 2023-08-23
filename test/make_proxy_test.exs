defmodule MakeProxyTest do
  use ExUnit.Case

  # # ensure a local make_proxy client and its server are started
  # # then run :
  # # WORKER_TYPE=make_proxy_client mix test --no-start

  # test "access make_proxy" do
  #   {status, sock} = :gen_tcp.connect(~c"localhost", 7070, mode: :binary, packet: 0)
  #   assert(status == :ok)
  #   :ok = :gen_tcp.close(sock)
  # end

  # test "example.org" do
  #   {:ok, sock} = :gen_tcp.connect(~c"localhost", 7070, mode: :binary, packet: 0, active: false)
  #   :ok = :gen_tcp.send(sock, "GET http://example.org/ HTTP/1.1\r\nHost: example.org\r\n\r\n")

  #   {:ok, body} = :gen_tcp.recv(sock, 0)

  #   refute(:binary.match(body, "HTTP/1.1 200 OK") == :nomatch)
  #   :ok = :gen_tcp.close(sock)
  # end

  # test "example.org/favicon.ico NOT FOUND" do
  #   {:ok, sock} = :gen_tcp.connect(~c"localhost", 7070, mode: :binary, packet: 0, active: false)

  #   :ok =
  #     :gen_tcp.send(
  #       sock,
  #       "GET http://example.org/favicon.ico HTTP/1.1\r\nHost: example.org\r\n\r\n"
  #     )

  #   {:ok, body} = :gen_tcp.recv(sock, 0)
  #   refute(:binary.match(body, "HTTP/1.1 404 Not Found") == :nomatch)
  #   :ok = :gen_tcp.close(sock)
  # end
end
