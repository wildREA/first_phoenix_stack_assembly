defmodule FirstPhoenixStackAssemblyWeb.PageControllerTest do
  use FirstPhoenixStackAssemblyWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Peace of mind tournament"
  end
end
