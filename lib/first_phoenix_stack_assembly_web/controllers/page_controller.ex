defmodule FirstPhoenixStackAssemblyWeb.PageController do
  use FirstPhoenixStackAssemblyWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
