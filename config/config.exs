import Config

config :make_proxy,
  server_addr: "127.0.0.1",
  server_port: 7071,
  client_port: 7070,
  key: "1234567890abcdef"

import_config "#{config_env()}.exs"