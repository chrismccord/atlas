defmodule Atlas.Logger do
  import Atlas, only: [database_config: 0]

  def log_path do
    Path.join([:code.lib_dir(:atlas, :log), "#{Mix.env}.log"])
  end

  def log_level, do: database_config[:log_level]

  def enabled?(:debug), do: log_level == :debug
  def enabled?(:info), do: enabled?(:debug) || log_level == :info
  def enabled?(:warn) do
    enabled?(:debug) || enabled?(:info) || log_level == :warn
  end

  def info(string) do
    if enabled?(:info), do: puts(string)
  end

  def debug(string) do
    if enabled?(:debug), do: puts(string)
  end

  def warn(string) do
    if enabled?(:warn), do: puts(string)
  end

  def puts(string) do
    :gen_server.call :logger_server, {:write, string}
    if in_console?, do: IO.puts string
  end

  def in_console?, do: IEx.started?
end