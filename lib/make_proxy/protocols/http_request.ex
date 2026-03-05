defmodule MakeProxy.HttpRequest do
  @moduledoc false
  defstruct status: :more,
            method: nil,
            host: nil,
            port: nil,
            content_length: 0,
            current_length: 0,
            next_data: ""
end
