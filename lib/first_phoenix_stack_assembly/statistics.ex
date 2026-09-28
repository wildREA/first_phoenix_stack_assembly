# Preparation functions
defmodule Statistics do
  defstruct [:id, :name, :team, :elo_count, :win_rate]

  # POST
  def parse_player_data_to_json(id, name, team, elo_count, win_rate) do
    map = %{
      "id" => id,
      "name" => name,
      "team" => team,
      "elo_count" => elo_count,
      "win_rate" => win_rate
    }

    Jason.encode(map)
  end

  # POST
  def parse_match_data_to_json(id, challenger_team, challenger_score, contender_team, contender_score) do
    map = %{
      "id" => id,
      "challenger_team" => challenger_team,
      "challenger_score" => challenger_score,
      "contender_team" => contender_team,
      "contender_score" => contender_score
    }

    Jason.encode(map)
  end

  # POST
  def remove_player_data_by_json_id(%{"id" => id}, socket) do
    socket = Phoenix.LiveView.stream_delete(socket, :players, %{id: id})
    {:no_reply, Phoenix.LiveView.put_flash(socket, :info, "Post #{id} was deleted")}
  end
end
