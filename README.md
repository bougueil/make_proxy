# MakeProxy
[![Test](https://github.com/bougueil/make_proxy/actions/workflows/ci.yml/badge.svg)](https://github.com/bougueil/make_proxy/actions/workflows/ci.yml)

Fork of erlang [make-proxy](https://github.com/yueyoum/make-proxy) for Elixir with supervisor and Systemd.

MakeProxy needs to be installed on a server and its clients.



### build
#### server
```
cd make_proxy
WORKER_TYPE=make_proxy_server MIX_ENV=prod mix release
```
#### client
```
cd make_proxy
WORKER_TYPE=make_proxy_client MIX_ENV=prod mix release
```



### systemd

Systemd service: see the [mkprx.service](systemd/mkprx.service) systemd service example.

#### env variables :
- MKP_KEY=1234567890abcdef         *# must be 16 bytes*
- MKP_SERVER=127.0.0.1
- MKP_IV=bXlJVl9pc18xNl9ieXRlcw==
- MKP_MAX_CONNECTIONS=100	# higher value for crappy websites
- MKP_MAX_ACCEPTORS=20		# number of processes that accept connections

MKP_IV can be generated like this :
```
"bXlJVl9pc18xNl9ieXRlcw==" = :base64.encode "myIV_is_16_bytes"
```
where "myIV_is_16_bytes" is a 16 bytes string.
