defmodule MakeProxy.Client do
  @moduledoc false
  defstruct [:key, :ref, :socket, :remote, :protocol, :buffer, :keep_alive]
end
