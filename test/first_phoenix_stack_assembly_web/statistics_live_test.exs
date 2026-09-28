defmodule FirstPhoenixStackAssemblyWeb.StatisticsLiveTest do
  use FirstPhoenixStackAssemblyWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders seed ranking and matches", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#statistics-command-form")
    assert has_element?(view, "#player-1", "Anthony")
    assert has_element?(view, "#match-1", "Vitality")
  end

  test "adds a player and updates an existing player", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#statistics-command-form", command: "rank: Navi, Natus, 4000, 100")
    |> render_submit()

    assert has_element?(view, "#player-2", "Navi")
    assert has_element?(view, "#player-2", "Natus")

    view
    |> form("#statistics-command-form", command: "rank: Navi, 4200, 75")
    |> render_submit()

    assert has_element?(view, "#player-2", "4200")
    assert has_element?(view, "#player-2", "75%")
  end

  test "adds a match without changing player win rate", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#statistics-command-form", command: "match: Navi, 2, Vitality, 1")
    |> render_submit()

    assert has_element?(view, "#match-2", "Navi")
    assert has_element?(view, "#match-2", "2")
    assert has_element?(view, "#player-1", "100%")
  end

  test "removes only players", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("#player-1 button[phx-click=remove_player]")
    |> render_click()

    refute has_element?(view, "#player-1")
    assert has_element?(view, "#match-1", "Vitality")
    assert has_element?(view, "#players-empty")
  end

  test "invalid commands leave the data unchanged and show an error", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#statistics-command-form", command: "rank: Anthony, Navi, 4000")
    |> render_submit()

    assert has_element?(view, "#player-1", "Anthony")
    assert has_element?(view, "#flash-error")
  end
end
