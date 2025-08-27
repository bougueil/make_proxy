defmodule MakeProxy.Logger do
  @moduledoc """
  Logging conveniences for MakeProxy servers
  """

  require Logger

  @doc """
  Start logging Thousand Island at the specified log level. Valid values for log
  level are `:error`, `:info`, `:debug`, and `:trace`. Enabling a given log
  level implicitly enables all higher log levels as well.
  """
  @spec attach_events() :: :ok | {:error, :already_exists}
  def attach_events do
    events = [
      [:make_proxy, :connection, :server],
      [:make_proxy, :connection, :client]
    ]

    :telemetry.attach_many("#{__MODULE__}.error", events, &__MODULE__.log_error/4, nil)
  end

  @doc false
  @spec log_error(
          :telemetry.event_name(),
          :telemetry.event_measurements(),
          :telemetry.event_metadata(),
          :telemetry.handler_config()
        ) :: :ok
  def log_error(
        [:make_proxy, :connection, server_type],
        _measurements,
        %{error: error, remote_address: remote_address, ctx: ctx} = _metadata,
        _config
      ) do
    Logger.error(
      "alert make_proxy_#{server_type} access from #{remote_address |> :inet.ntoa()} error=#{inspect(error)} ctx=#{inspect(ctx)}"
    )
  end

  def log_error(_event, _measurements, _metadata, _config) do
  end
end
