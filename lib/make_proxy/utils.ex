defmodule MakeProxy.Utils do
  @moduledoc false

  def connect_to_remote() do
    :gen_tcp.connect(
      Application.fetch_env!(:make_proxy, :remote_addr),
      Application.fetch_env!(:make_proxy, :port),
      [{:inet_backend, :socket}, {:active, :once}, {:packet, 4}, :binary]
    )
  end
end
