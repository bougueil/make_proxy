# MakeProxy

Fork of erlang [make-proxy](https://github.com/yueyoum/make-proxy) rewritten in Elixir with a supervisor and Systemd.


### build a release (executable)
```
# server
WORKER_TYPE=make_proxy_server MIX_ENV=prod mix release

# client
WORKER_TYPE=make_proxy_client MIX_ENV=prod mix release
```



### systemd

Systemd service : see the [mkprx.service](systemd/server/mkprx.service) server or [mkprx.service](systemd/client/mkprx.service) client.

Releases are built *without* erts which results in small services.<br>
Those micro services can then be stacked on very small instance servers.
