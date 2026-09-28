defmodule FirstPhoenixStackAssemblyWeb.StatisticsLive do
  use FirstPhoenixStackAssemblyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       players: Statistics.seed_players(),
       matches: Statistics.seed_matches(),
       next_match_id: 2,
       form: to_form(%{"command" => ""})
     )}
  end

  @impl true
  def handle_event("submit_command", %{"command" => command}, socket) do
    case Statistics.parse_command(command) do
      {:ok, {:add_player, name, team, elo_count, win_rate}} ->
        add_player(socket, name, team, elo_count, win_rate)

      {:ok, {:update_player, name, elo_count, win_rate}} ->
        update_player(socket, name, elo_count, win_rate)

      {:ok, {:add_match, challenger_team, challenger_score, contender_team, contender_score}} ->
        add_match(socket, challenger_team, challenger_score, contender_team, contender_score)

      {:ok, {:remove_player, name}} ->
        remove_player(socket, name)

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("remove_player", %{"name" => name}, socket) do
    remove_player(socket, name)
  end

  defp add_player(socket, name, team, elo_count, win_rate) do
    case Statistics.add_player(socket.assigns.players, name, team, elo_count, win_rate) do
      {:ok, player} ->
        {:noreply,
         socket
         |> update(:players, &(&1 ++ [player]))
         |> assign(:form, to_form(%{"command" => ""}))
         |> put_flash(:info, "Added #{player.name} to the ranking.")}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp update_player(socket, name, elo_count, win_rate) do
    case Statistics.update_player(socket.assigns.players, name, elo_count, win_rate) do
      {:ok, players} ->
        {:noreply,
         socket
         |> assign(players: players, form: to_form(%{"command" => ""}))
         |> put_flash(:info, "Updated #{name}'s ranking data.")}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp add_match(socket, challenger_team, challenger_score, contender_team, contender_score) do
    case Statistics.add_match(
           socket.assigns.matches,
           challenger_team,
           challenger_score,
           contender_team,
           contender_score
         ) do
      {:ok, match} ->
        {:noreply,
         socket
         |> update(:matches, &(&1 ++ [match]))
         |> update(:next_match_id, &(&1 + 1))
         |> assign(:form, to_form(%{"command" => ""}))
         |> put_flash(
           :info,
           "Added the #{match.challenger_team} versus #{match.contender_team} match."
         )}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp remove_player(socket, name) do
    case Statistics.remove_player(socket.assigns.players, name) do
      {:ok, players} ->
        {:noreply,
         socket
         |> assign(players: players, form: to_form(%{"command" => ""}))
         |> put_flash(:info, "Removed #{name} from the ranking.")}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def format_percentage(value) when is_float(value) do
    value
    |> :erlang.float_to_binary(decimals: 2)
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
  end

  def format_percentage(value), do: to_string(value)
end
