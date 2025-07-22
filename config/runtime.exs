import Config

if System.get_env("WORKER_TYPE") == "make_proxy_client" do
  remote_addr = System.get_env("MKP_SERVER")
  params = Application.compile_env!(:make_proxy, :make_proxy_server)
  port = params[:port]
  {:ok, addr} = :inet.getaddr(to_charlist(remote_addr), :inet)

  config :make_proxy,
    remote_addr: addr,
    port: port
end

config :make_proxy,
  key: System.get_env("MKP_KEY")
