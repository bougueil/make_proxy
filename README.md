# MakeProxy

Fork of erlang [make-proxy](https://github.com/yueyoum/make-proxy) rewritten in Elixir with supervisor and Systemd.


### build a release (executable)
```
# server
WORKER_TYPE=make_proxy_server MIX_ENV=prod mix release

# client
WORKER_TYPE=make_proxy_client MIX_ENV=prod mix release
```



### systemd

Systemd service : see the [mkprx.service](systemd/server/mkprx.service) server or [mkprx.service](systemd/client/mkprx.service) client.

The releases are built *without* erts which results in small, a few MB, services.<br>
Those micro-services can be stacked on very small instance servers.
