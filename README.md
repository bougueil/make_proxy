# MakeProxy
[![Test](https://github.com/bougueil/make_proxy/actions/workflows/ci.yml/badge.svg)](https://github.com/bougueil/make_proxy/actions/workflows/ci.yml)

Fork of Erlang [make-proxy](https://github.com/yueyoum/make-proxy) for Elixir with supervisor and Systemd.

`make_proxy` needs to be installed on a server (the proxy) and its clients.

---

### build
#### server
```
cd make_proxy
WORKER_TYPE=make_proxy_server MIX_ENV=prod mix do deps.get + release
```
#### client
```
cd make_proxy
WORKER_TYPE=make_proxy_client MIX_ENV=prod mix do deps.get + release
```
---

### systemd

#### 🔐 Configure env variables :
First review the ./.env file.

- ERL_EPMD_ADDRESS=127.0.0.1
- MKP_KEY=1234567890abcdef   # must be 16 bytes*
- MKP_SERVER=127.0.0.1
- MKP_IV=bXlJVl9pc18xNl9ieXRlcw==

MKP_IV can be generated like this :

```
	"bXlJVl9pc18xNl9ieXRlcw==" = Base.encode64 "myIV_is_16_bytes"
```
where "myIV_is_16_bytes" is a 16 bytes string.

- MKP_MAX_CONNECTIONS=100	 # higher value for crappy websites
- MKP_MAX_ACCEPTORS=20		 # number of processes that accept connections

#### generate the systemd unit file with :
```
./setup-make_proxy-mount.sh 

```

#### 🔍 Verify Mount

Check systemd service:

```bash
systemctl --user status make_proxy.service
```

Ensure make_proxy is listening either on port 7070 for client or 7071 for server :

```bash
ss -ltpn
```
---

#### 🧼 Uninstall

To remove the systemd setup:

```bash
systemctl --user disable --now make_proxy.service
rm ~/.config/systemd/user/make_proxy.service
```

---

#### 🛟 Troubleshooting

If make_proxy isn't listening on 7070 or 7071:

```bash
journalctl --user -u make_proxy.service
```

To restart the service manually:

```bash
systemctl --user restart make_proxy.service
```

---

### fail2ban

fail2ban configuration: see the [jail.local](fail2ban/jail.local) fail2ban conf example and filter.

This fail2ban prevents unauthorized access to `make_proxy` server listening on public port 7071.

