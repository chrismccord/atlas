defmodule Atlas.Database.Adapter do
  @moduledoc """
  Defines the behaviour for an Atlas database adapter
  """

  use Behaviour
  alias Atlas.Database.Server.ConfigInfo


  defcallback connect(config_info :: ConfigInfo) :: { :ok, pid } |
                                                    { :error, term }

  defcallback execute_query(pid, query :: binary) :: { :ok, count :: integer, cols :: list, rows :: list } |
                                                     { :error, term }

  defcallback execute_prepared_query(pid, query :: binary , args :: list) :: { :ok, prepared_query :: binary } |
                                                                             { :error, term }

  defcallback quote_column(column :: binary) :: column :: binary

  defcallback quote_tablename(table :: binary) :: tablename :: binary

  defcallback quote_value(value :: binary) :: value :: binary

  defcallback escape(value :: binary) :: value :: binary
end