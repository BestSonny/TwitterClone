defmodule App.TweetChannel do
  use App.Web, :channel
  alias App.User
  alias App.Tag
  alias App.Tagging
  require Logger
  alias App.Retweet
  alias App.Tweet
  alias App.Follower
  import Ecto.Changeset
  
  def join("signup", _params, socket) do
    send self(), {:sign_up, _params}
    {:ok, socket}
  end

  def handle_info({:sign_up, _params}, socket), do: socket |> do_sign_up(_params)

  defp do_sign_up(socket, _params) do
    changeset = User.changeset(%User{}, _params) |> User.with_password_hash
    changeset = put_change(changeset, :profile_picture, "default_profile.png")
    case Repo.insert changeset do
      {:ok, user} ->
        push socket, "sign_up", %{status: "successfully sign up"}
      {:error, changeset} ->
        push socket, "sign_up", %{status: "failed to sign up"}
    end
    {:noreply, socket}
  end

  def join("search", _params, socket) do
      send self(), {:search, _params}
      {:ok, socket}
  end

  defp tweets_json(tweet) do
    %{
      text: tweet.text,
      retweet_id: tweet.retweet_id,
      current_user_favorite_id: tweet.current_user_favorite_id,
      current_user_retweet_id: tweet.current_user_retweet_id,
    }
  end

  def handle_info({:search, _params}, socket), do: socket |> search( _params)

  defp search(socket,  _params) do
    IO.inspect _params["query"]
    tweets = (from t in Tweet, where: like(t.text, ^("%#{_params["query"]}%")))
    |> Repo.all() |> Repo.preload(:user)
    IO.inspect tweets
    push socket, "search", %{tweet: %{
      tweets: Enum.map(tweets, &tweets_json/1)
    }}
    {:noreply, socket}
  end


  def join("retweet", _params, socket) do
      case authenticate _params["login"], _params["password"] do
        {:ok, user} ->
          with socket <- socket |> assign(:joined_at, NaiveDateTime.utc_now) do
            send self(), {:retweet, _params, user}
            {:ok, socket}
        end
        :error ->
          {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:retweet, _params, user}, socket), do: socket |> retweet( _params, user)

  defp retweet(socket, _params, user) do
    try do
      tweet = Repo.get! Tweet, _params["tweet_id"]
      if tweet.user_id === user.id do
        push socket, "retweet", %{status: "You are not allowed to retweet your own tweets"}
      else
        retweet_param = %{tweet_id: tweet.id, user_id: user.id}
        changeset = Retweet.changeset(%Retweet{}, retweet_param)
        try do
          Repo.insert! changeset
          push socket, "retweet", %{status: "successfully retweet"}
        rescue
          _ -> push socket, "retweet", %{status: "retweets pair has already been taken"}
        end
      end
    rescue
      _ ->  push socket, "retweet", %{status: "tweet_id #{_params["tweet_id"]} does not exist"}
    end
    {:noreply, socket}
  end

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

  def join("subscribe", _params, socket) do
      case authenticate _params["login"], _params["password"] do
        {:ok, user} ->
          with socket <- socket |> assign(:joined_at, NaiveDateTime.utc_now) do
            send self(), {:subscribe, _params, user}
            {:ok, socket}
        end
        :error ->
          {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:subscribe, _params, user}, socket), do: socket |> subscribe_user( _params, user)

  defp subscribe_user(socket,  _params, user) do
    {userid, _} = Integer.parse(_params["follow_id"])
    follower = %Follower{user_id: userid, follower_id: user.id}
    try do
        case Repo.insert Follower.changeset(follower, %{}) do
        {:ok, _follower} ->
            push socket, "subscribe", %{status: "Successfully followed this user"}
        {:error, _changeset} ->
            push socket, "subscribe", status: %{status: "Unable to follow this user"}
        end
    rescue
        _ -> push socket, "subscribe", status: %{status: "XXX to follow this user"}
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
