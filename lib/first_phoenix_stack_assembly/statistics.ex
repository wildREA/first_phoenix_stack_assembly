defmodule Statistics do
  defstruct [:id, :name, :team, :elo_count, :win_rate]

  @type player :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          team: String.t(),
          elo_count: non_neg_integer(),
          win_rate: number()
        }

  @type match :: %{
          id: pos_integer(),
          challenger_team: String.t(),
          challenger_score: non_neg_integer(),
          contender_team: String.t(),
          contender_score: non_neg_integer(),
          date: Date.t()
        }

  @spec seed_players() :: [player()]
  def seed_players do
    [%__MODULE__{id: 1, name: "Anthony", team: "Navi", elo_count: 4000, win_rate: 100}]
  end

  @spec seed_matches() :: [match()]
  def seed_matches do
    [new_match(1, "Vitality", 2, "FURIA", 0, ~D[2026-09-20])]
  end

  @spec next_id([map()]) :: pos_integer()
  def next_id(items) do
    Enum.max_by(items, & &1.id, fn -> %{id: 0} end).id + 1
  end

  @spec parse_command(String.t()) :: {:ok, tuple()} | {:error, String.t()}
  def parse_command(input) when is_binary(input) do
    case String.split(input, ":", parts: 2) do
      [command, values] -> parse_command(String.downcase(String.trim(command)), values)
      _ -> {:error, "Use rank:, match:, or remove: followed by comma-separated values."}
    end
  end

  defp parse_command("rank", values) do
    case split_values(values) do
      [name, team, elo, win_rate] ->
        with {:ok, elo} <- parse_integer(elo, "Elo"),
             {:ok, win_rate} <- parse_percentage(win_rate) do
          {:ok, {:add_player, name, team, elo, win_rate}}
        end

      [name, elo, win_rate] ->
        with {:ok, elo} <- parse_integer(elo, "Elo"),
             {:ok, win_rate} <- parse_percentage(win_rate) do
          {:ok, {:update_player, name, elo, win_rate}}
        end

      _ ->
        {:error, "rank: requires name, team, Elo, win rate or name, Elo, win rate."}
    end
  end

  defp parse_command("match", values) do
    case split_values(values) do
      [challenger_team, challenger_score, contender_team, contender_score] ->
        with {:ok, challenger_score} <- parse_score(challenger_score),
             {:ok, contender_score} <- parse_score(contender_score) do
          {:ok, {:add_match, challenger_team, challenger_score, contender_team, contender_score}}
        end

      _ ->
        {:error, "match: requires challenger, score, contender, score."}
    end
  end

  defp parse_command("remove", values) do
    case split_values(values) do
      [name] -> {:ok, {:remove_player, name}}
      _ -> {:error, "remove: requires one player name."}
    end
  end

  defp parse_command(_, _), do: {:error, "Unknown command. Use rank:, match:, or remove:."}

  @spec add_player([player()], String.t(), String.t(), non_neg_integer(), number()) ::
          {:ok, player()} | {:error, String.t()}
  def add_player(players, name, team, elo_count, win_rate) do
    with :ok <- validate_text(name, "Player name"),
         :ok <- validate_text(team, "Team"),
         :ok <- validate_percentage(win_rate),
         false <- Enum.any?(players, &same_name?(&1.name, name)) do
      player = %__MODULE__{
        id: next_id(players),
        name: String.trim(name),
        team: String.trim(team),
        elo_count: elo_count,
        win_rate: win_rate
      }

      {:ok, player}
    else
      true -> {:error, "A player with that name already exists."}
      {:error, message} -> {:error, message}
    end
  end

  @spec update_player([player()], String.t(), non_neg_integer(), number()) ::
          {:ok, [player()]} | {:error, String.t()}
  def update_player(players, name, elo_count, win_rate) do
    with :ok <- validate_text(name, "Player name"),
         :ok <- validate_percentage(win_rate),
         {:ok, _player} <- find_player(players, name) do
      updated_players =
        Enum.map(players, fn player ->
          if same_name?(player.name, name) do
            %{player | elo_count: elo_count, win_rate: win_rate}
          else
            player
          end
        end)

      {:ok, updated_players}
    end
  end

  @spec remove_player([player()], String.t()) :: {:ok, [player()]} | {:error, String.t()}
  def remove_player(players, name) do
    with :ok <- validate_text(name, "Player name"),
         {:ok, _player} <- find_player(players, name) do
      {:ok, Enum.reject(players, &same_name?(&1.name, name))}
    end
  end

  @spec add_match([match()], String.t(), non_neg_integer(), String.t(), non_neg_integer()) ::
          {:ok, match()} | {:error, String.t()}
  def add_match(matches, challenger_team, challenger_score, contender_team, contender_score) do
    with :ok <- validate_text(challenger_team, "Challenger team"),
         :ok <- validate_text(contender_team, "Contender team"),
         false <-
           Enum.any?(matches, fn match ->
             same_match?(
               match,
               challenger_team,
               challenger_score,
               contender_team,
               contender_score
             )
           end) do
      match =
        new_match(
          next_id(matches),
          String.trim(challenger_team),
          challenger_score,
          String.trim(contender_team),
          contender_score,
          Date.utc_today()
        )

      {:ok, match}
    else
      true -> {:error, "That match already exists."}
      {:error, message} -> {:error, message}
    end
  end

  @spec parse_player_data_to_json(integer(), String.t(), String.t(), integer(), number()) ::
          {:ok, String.t()} | {:error, Jason.EncodeError.t()}
  def parse_player_data_to_json(id, name, team, elo_count, win_rate) do
    Jason.encode(%{
      "id" => id,
      "name" => name,
      "team" => team,
      "elo_count" => elo_count,
      "win_rate" => win_rate
    })
  end

  @spec parse_match_data_to_json(integer(), String.t(), integer(), String.t(), integer()) ::
          {:ok, String.t()} | {:error, Jason.EncodeError.t()}
  def parse_match_data_to_json(
        id,
        challenger_team,
        challenger_score,
        contender_team,
        contender_score
      ) do
    Jason.encode(%{
      "id" => id,
      "challenger_team" => challenger_team,
      "challenger_score" => challenger_score,
      "contender_team" => contender_team,
      "contender_score" => contender_score
    })
  end

  defp split_values(values) do
    values
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp parse_integer(value, label) do
    case Integer.parse(value) do
      {integer, ""} when integer >= 0 -> {:ok, integer}
      _ -> {:error, "#{label} must be a non-negative whole number."}
    end
  end

  defp parse_score(value), do: parse_integer(value, "Score")

  defp parse_percentage(value) do
    case Float.parse(value) do
      {percentage, ""} when percentage >= 0 and percentage <= 100 -> {:ok, percentage}
      _ -> {:error, "Win rate must be a number between 0 and 100."}
    end
  end

  defp validate_percentage(value) when is_number(value) and value >= 0 and value <= 100, do: :ok
  defp validate_percentage(_value), do: {:error, "Win rate must be a number between 0 and 100."}

  defp validate_text(value, label) when is_binary(value) do
    if String.trim(value) == "", do: {:error, "#{label} cannot be blank."}, else: :ok
  end

  defp validate_text(_value, label), do: {:error, "#{label} cannot be blank."}

  defp find_player(players, name) do
    case Enum.find(players, &same_name?(&1.name, name)) do
      nil -> {:error, "Player not found."}
      player -> {:ok, player}
    end
  end

  defp same_name?(left, right), do: normalize(left) == normalize(right)

  defp same_match?(match, challenger_team, challenger_score, contender_team, contender_score) do
    normalize(match.challenger_team) == normalize(challenger_team) and
      match.challenger_score == challenger_score and
      normalize(match.contender_team) == normalize(contender_team) and
      match.contender_score == contender_score
  end

  defp normalize(value), do: value |> String.trim() |> String.downcase()

  defp new_match(id, challenger_team, challenger_score, contender_team, contender_score, date) do
    %{
      id: id,
      challenger_team: challenger_team,
      challenger_score: challenger_score,
      contender_team: contender_team,
      contender_score: contender_score,
      date: date
    }
  end
end
