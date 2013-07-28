defmodule Atlas.Logger do
  import Atlas, only: [database_config: 0]

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

  def puts(string), do: IO.puts string
end