defmodule StatisticsTest do
  use ExUnit.Case, async: true

  test "parses player creation and update commands" do
    assert {:ok, {:add_player, "Navi", "Natus", 4000, 100.0}} =
             Statistics.parse_command("rank: Navi, Natus, 4000, 100")

    assert {:ok, {:update_player, "Navi", 4200, 75.5}} =
             Statistics.parse_command("RANK: Navi, 4200, 75.5")
  end

  test "parses matches and removals" do
    assert {:ok, {:add_match, "Vitality", 2, "FURIA", 0}} =
             Statistics.parse_command("match: Vitality, 2, FURIA, 0")

    assert {:ok, {:remove_player, "Anthony"}} = Statistics.parse_command("remove: Anthony")
  end

  test "rejects malformed commands and invalid percentages" do
    assert {:error, _message} = Statistics.parse_command("rank: Anthony, Navi, 4000")
    assert {:error, _message} = Statistics.parse_command("rank: Anthony, Navi, 4000, 101")
    assert {:error, _message} = Statistics.parse_command("delete: Anthony")
  end

  test "adds, updates, and removes players with case-insensitive exact names" do
    players = Statistics.seed_players()

    assert {:ok, player} = Statistics.add_player(players, "Navi", "Natus", 4000, 100)
    assert player.id == 2

    assert {:error, "A player with that name already exists."} =
             Statistics.add_player(players, "anthony", "Other", 3000, 50)

    assert {:ok, updated_players} = Statistics.update_player(players, "aNtHoNy", 4200, 75)
    assert [%Statistics{elo_count: 4200, win_rate: 75}] = updated_players

    assert {:ok, []} = Statistics.remove_player(players, "ANTHONY")
    assert {:error, "Player not found."} = Statistics.remove_player(players, "Anthony Smith")
  end

  test "rejects exact duplicate matches case-insensitively" do
    matches = Statistics.seed_matches()

    assert {:error, "That match already exists."} =
             Statistics.add_match(matches, "vitality", 2, "furia", 0)

    assert {:ok, match} = Statistics.add_match(matches, "Navi", 2, "Vitality", 1)
    assert match.id == 2
    assert match.date == Date.utc_today()
  end
end
