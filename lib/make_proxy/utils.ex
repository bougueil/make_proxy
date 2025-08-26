defmodule MakeProxy.Utils do
  @moduledoc false

  @connect_opts [:binary, active: :once, packet: 4]

  def connect_to_remote do
    :gen_tcp.connect(
      Application.fetch_env!(:make_proxy, :remote_addr),
      Application.fetch_env!(:make_proxy, :remote_port),
      @connect_opts
    )
  end
end
