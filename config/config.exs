import Config

config :make_proxy,
  server_port: 7071,
  client_port: 7070

config :logger, :default_handler,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  config: [
    file: ~c"system.log",
    filesync_repeat_interval: 15000,
    file_check: 15000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

import_config "#{config_env()}.exs"
