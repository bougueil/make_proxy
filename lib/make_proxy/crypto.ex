defmodule MakeProxy.Crypto do

  @moduledoc false

  @datalength 16

  @spec encrypt({fun(), fun()}, binary()) :: binary()
  def encrypt({encrypt, _}, binary) do
    binary_length = byte_size(binary)
    rem = Integer.mod(binary_length + 4, @datalength)
    additional_length = @datalength - rem

    final_binary =
      <<binary_length::32-integer-big, binary::binary, 0::size(additional_length)-unit(8)>>

    encrypt.(final_binary)
  end

  @spec decrypt({fun(), fun()}, binary()) :: {:ok, binary()} | {:error, term()}
  def decrypt({_, decrypt}, binary) do
    data = decrypt.(binary)

    try do
      <<len::32-integer-big, real_data::bytes-size(len), _::binary>> = data
      {:ok, real_data}
    catch
      error, reason ->
        {:error, {error, reason}}
    end
  end
end
