# MakeProxy

Fork of erlang [make-proxy](https://github.com/yueyoum/make-proxy) rewritten in Elixir with supervisor and Systemd.


### build a release (executable)
"bXlJVl9pc18xNl9ieXRlcw==" = :base64.encode "myIV_is_16_bytes"
```
# server
IV=bXlJVl9pc18xNl9ieXRlcw== WORKER_TYPE=make_proxy_server MIX_ENV=prod mix release

# client
IV=bXlJVl9pc18xNl9ieXRlcw== WORKER_TYPE=make_proxy_client MIX_ENV=prod mix release
```



### systemd

Systemd service : see the [mkprx.service](systemd/mkprx.service) systemd service.

The release is built *without* erts which results in a small, a few MB, systemd service.<br>
Those micro-services can be stacked on very small instance servers.
