import Config

if Application.compile_env!(:make_proxy, :worker) do
  remote_addr = System.get_env("MKP_SERVER")
  params = Application.compile_env!(:make_proxy, :make_proxy_server)
  port = params[:port]
  {:ok, addr} = :inet.getaddr(to_charlist(remote_addr), :inet)

  config :make_proxy,
    remote_addr: addr,
    remote_port: port
end

key = System.get_env("MKP_KEY")
iv = System.get_env("MKP_IV") |> Base.decode64!()

key =
  case :erlang.system_info(:otp_release) >= [?2, ?4] do
    true ->
      {fn bin -> :crypto.crypto_one_time(:aes_128_cbc, key, iv, bin, true) end,
       fn bin -> :crypto.crypto_one_time(:aes_128_cbc, key, iv, bin, false) end}

    false ->
      {fn bin -> :crypto.block_encrypt(:aes_cbc128, key, iv, bin) end,
       fn bin -> :crypto.block_decrypt(:aes_cbc128, key, iv, bin) end}
  end

config :make_proxy,
  key: key
