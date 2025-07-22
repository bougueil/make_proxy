defmodule MakeProxy.Client.Protocol do
  alias MakeProxy.Client

  @moduledoc false

  @doc """
  return true if h is a valid protocol header
  """
  @callback detect_head(h :: byte()) :: boolean()

  @doc """
  serve a request.
  """
  @callback request(data :: binary(), state :: %Client{}) ::
              {:ok, state :: %Client{}}
              | {:error, reason :: term()}
end
