defmodule MakeProxy.WorkerState do
  @moduledoc false
  defstruct [:key, :remote, :handler, keep_alive: false, buffer: ""]
end
