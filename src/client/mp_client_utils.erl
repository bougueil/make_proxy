%%%-------------------------------------------------------------------
%%% @author wang
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Oct 2016 下午2:28
%%%-------------------------------------------------------------------
-module(mp_client_utils).
-author("wang").

%% API
-export([connect_to_remote/0]).

connect_to_remote() ->
    {ok, RemoteAddr} = application:get_env(make_proxy, server_addr),
    {ok, RemotePort} = application:get_env(make_proxy, server_port),
    {ok, Addr} = inet:getaddr(charlist(RemoteAddr), inet),
    gen_tcp:connect(Addr, RemotePort, [{inet_backend,socket}, {active, once}, {packet, 4}, binary]).


charlist(Str) when is_list(Str) ->
    Str;
charlist(Str) ->
    binary:bin_to_list(Str).
