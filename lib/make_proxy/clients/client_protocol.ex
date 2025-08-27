defmodule MakeProxy.Client.Protocol do
  alias MakeProxy.WorkerState

  @moduledoc false

  @doc """
  return true if h is a valid protocol header
  """
  @callback detect_head(h :: byte()) :: boolean()

  @doc """
  serve a request.
  """
  @callback request(data :: binary(), socket :: term(), state :: %WorkerState{}) ::
              {:ok, state :: %WorkerState{}}
              | {:error, reason :: term()}
end
