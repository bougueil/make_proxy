import Config

config :make_proxy,
  server_addr: "51.15.95.198",
  server_port: 7071,
  client_port: 7070,
  key: "1234667890abcdef"

import_config "#{config_env()}.exs"
