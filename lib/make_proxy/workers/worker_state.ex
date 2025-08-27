defmodule MakeProxy.WorkerState do
  @moduledoc false
  defstruct [:key, :remote, :protocol, keep_alive: false, buffer: ""]
end
