-module(mp_crypto).
-export([
    encrypt/2,
    decrypt/2
]).

-define(DATALENGTH, 16).
-define(IV,base64:decode(os:getenv("IV"))).
-define(IS_OTP_24, erlang:list_to_binary(erlang:system_info(otp_release)) >= <<"24">>).

-ifdef(IS_OTP_24).
-define(ENCRYPT(Key, IV, Bin), crypto:crypto_one_time(aes_128_cbc, Key, IV, Bin, true)).
-define(DECRYPT(Key, IV, Bin), crypto:crypto_one_time(aes_128_cbc, Key, IV, Bin, false)).
-else.
-define(ENCRYPT(Key, IV, Bin), crypto:block_encrypt(aes_cbc128, Key, IV, Bin)).
-define(DECRYPT(Key, IV, Bin), crypto:block_decrypt(aes_cbc128, Key, IV, Bin)).
-endif.

-spec encrypt(nonempty_string(), binary()) -> binary().
encrypt(Key, Binary) ->
    BinaryLength = byte_size(Binary),
    Rem = (BinaryLength + 4) rem ?DATALENGTH,
    AdditionalLength = ?DATALENGTH - Rem,
    FinalBinary = <<BinaryLength:32/integer-big, Binary/binary, 0:AdditionalLength/unit:8>>,
    ?ENCRYPT(Key, ?IV, FinalBinary).

-spec decrypt(nonempty_string(), binary()) ->
    {ok, binary()}
    | {error, term()}.
decrypt(Key, Binary) ->
    Data = ?DECRYPT(Key, ?IV, Binary),
    try
        <<Length:32/integer-big, RealData:Length/binary, _Rest/binary>> = Data,
        {ok, RealData}
    catch
        Error:Reason ->
            {error, {Error, Reason}}
    end.
