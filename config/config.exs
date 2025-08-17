import Config

config :make_proxy,
  make_proxy_server: [port: 7071, worker: MakeProxy.Worker.Server],
  make_proxy_client: [port: 7070, worker: MakeProxy.Worker.Client],
  worker: System.fetch_env!("WORKER_TYPE") |> String.to_atom()

config :logger, :default_handler,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :default_formatter, format: "$time $metadata[$level] $message\n"

import_config "#{config_env()}.exs"
