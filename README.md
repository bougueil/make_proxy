# MakeProxy

Fork of make-proxy in Elixir

# build a release 
WORKER_TYPE=make_proxy_client MIX_ENV=prod mix release

# systemd
The release is without erts.
Systemd service : see systemd/[client|server]/mkprx.service
