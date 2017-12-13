defmodule App.TweetChannel do
  use App.Web, :channel
  alias App.User
  alias App.Tag
  alias App.Tagging
  alias App.Tweet
  require Logger

  def join("tweet", _params, socket) do
      case authenticate _params["login"], _params["password"] do
        {:ok, user} ->
          with socket <- socket |> assign(:joined_at, NaiveDateTime.utc_now) do
            send self(), {:send_tweet, _params, user}
            {:ok, socket}
        end
        :error ->
          {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:send_tweet, _params, user}, socket), do: socket |> send_tweet( _params, user)

  defp send_tweet(socket,  _params, user) do
    {state, _} = Repo.transaction fn ->
      tweet_changeset = Tweet.changeset %Tweet{user_id: user.id}, %{"text" => _params["tweet"]}
      case Repo.insert tweet_changeset do
        {:ok, tweet} ->
          create_taggings(tweet)
        _ ->
      end
    end
    if state == :ok do
      push socket, "send_tweet", %{status: "successfully send tweet"}
    else
      push socket, "send_tweet", %{status: "failed to send tweet "}
    end
    {:noreply, socket}
  end

  defp authenticate(login, password) do
    case Repo.get_by User, login: login do
      nil  ->
        :error
      user ->
        if User.validate_password password, user.password_hash do
          {:ok, user}
        else
          :error
        end
    end
  end

  defp create_taggings(tweet) do
      tags = extract_tags(tweet.text)
      Enum.map(tags, fn(name) ->
        tag = create_or_get_tag(name)
        tagging_param = %{tag_id: tag.id, tweet_id: tweet.id}
        tagging_changeset = Tagging.changeset(%Tagging{}, tagging_param)
        Repo.insert! tagging_changeset
      end)
    end

    defp extract_tags(text) do
      Regex.scan(~r/\S*#(?<tag>:\[[^\]]|[a-zA-Z0-9]+)/, text, capture: :all_names) |> List.flatten
    end

    defp create_or_get_tag(name) do
      case Repo.one from t in Tag, where: ilike(t.name, ^name) do
        nil ->
          tag_param = %{name: name}
          tag_changeset = Tag.changeset(%Tag{}, tag_param)
          Repo.insert! tag_changeset
        tag ->
          tag
      end
  end

end