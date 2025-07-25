defmodule MakeProxy.Crypto do
  @moduledoc false

  @datalength 16

  @spec encrypt({fun(), fun()}, binary()) :: binary()
  def encrypt({encrypt, _}, bin) do
    bin_len = byte_size(bin)
    rem = rem(bin_len + 4, @datalength)
    additional_length = @datalength - rem

    encrypt.(<<bin_len::32-integer-big, bin::binary, 0::size(additional_length)-unit(8)>>)
  end

  @spec decrypt({fun(), fun()}, binary()) :: {:ok, binary()} | {:error, term()}
  def decrypt({_, decrypt}, bin) do
    try do
      <<len::32-integer-big, real_data::bytes-size(len), _::binary>> = decrypt.(bin)
      {:ok, real_data}
    catch
      error, reason ->
        {:error, {error, reason}}
    end
  end
end
