defmodule Atlas.Logger do

  def log_path do
    Path.join(["log", "#{Mix.env}.log"]) |> Path.expand
  end

  def log_level(repo), do: Keyword.get(repo.database_config, :log_level)

  def enabled?(:debug, repo), do: log_level(repo) == :debug
  def enabled?(:info, repo), do: enabled?(:debug, repo) || log_level(repo) == :info
  def enabled?(:warn, repo) do
    enabled?(:debug, repo) || enabled?(:info, repo) || log_level(repo) == :warn
  end

  def info(string, repo) do
    if enabled?(:info, repo), do: puts(string)
  end

  def debug(string, repo) do
    if enabled?(:debug, repo), do: puts(string)
  end

  def warn(string, repo) do
    if enabled?(:warn, repo), do: puts(string)
  end

  def puts(string) do
    :gen_server.call :logger_server, {:write, string}
    if in_console?, do: IO.puts string
  end

  def in_console?, do: Code.ensure_loaded?(IEx) && IEx.started?
end
