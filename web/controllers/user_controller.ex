defmodule App.UserController do
  use App.Web, :controller

  alias App.Tweet
  alias App.Retweet
  alias App.User
  alias App.Follower

  import Ecto.Changeset
  
  @num_tweets 10


  plug App.LoginRequired when action in [:edit, :update]
  plug App.SetUser when action in [:show]

  def index(conn, _params) do
    users = Repo.all User |> order_by([u], [asc: u.name])
    render conn, "index.html", users: users
  end

  def show(conn, _params) do
    user = conn.assigns[:user]
    changeset = Tweet.changeset %Tweet{}
    #added by keke to show the tweet posted by the user this current user is following
    query = """ 
    select distinct * from(
      SELECT t0.*, null as current_user_favorite_id, r2.id as current_user_retweet_id
        FROM tweets AS t0 
        LEFT OUTER JOIN retweets AS r2
        ON (r2.user_id in (select fw.user_id from followers fw where fw.follower_id=$1)) AND (r2.tweet_id = t0.id)
        where t0.id not in (
        select fa.tweet_id from favorites fa where fa.user_id = $1 
        union
        select re.tweet_id from retweets re where re.user_id = $1)
      Union
      SELECT t0.*, f1.id as current_user_favorite_id, r2.id as current_user_retweet_id
        FROM tweets AS t0 LEFT OUTER JOIN favorites AS f1
        ON (f1.user_id = $1) AND (f1.tweet_id = t0.id) LEFT OUTER JOIN retweets AS r2
        ON (r2.user_id = $1) AND (r2.tweet_id = t0.id) ) m
      order by m.inserted_at desc
      limit $2
    """
    res = Ecto.Adapters.SQL.query!(App.Repo, query, [user.id, @num_tweets])
    #IO.puts(", res: #{inspect res}")

    cols = Enum.map res.columns, &(String.to_atom(&1)) # b
    
    tweets = Enum.map res.rows, fn(row) ->
      struct(App.Tweet, Enum.zip(cols, row)) # c
    end
    tweets = tweets |> Repo.preload(:user)

    render conn, "show.html", user: user, changeset: changeset, tweets: tweets #added by keke
  end

  def edit(conn, %{"id" => id}) do
    user = Repo.get! User, id
    changeset = User.changeset user
    render conn, "edit.html", user: user, changeset: changeset
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get! User, id
    changeset = User.changeset user, user_params

    # authorize user update
    password = get_change(changeset, :password)
    unless User.validate_password password, user.password_hash do
      new_changeset = %{changeset | action: :update } |> add_error(:password, gettext "wrong password")
      render conn, "edit.html", user: user, changeset: new_changeset
    end

    # set new password? (optional)
    new_password = get_change changeset, :new_password
    changeset = if String.length(new_password) > 0 do
      put_change(changeset, :password, new_password) |> User.with_password_hash
    else
      changeset
    end

    photo = user_params["photo"]
    changeset = if photo do
      name = "profile_picture_" <> id
      dst = Path.join([:code.priv_dir(:app), "static", "images", name])
      File.cp! photo.path, dst
      put_change changeset, :profile_picture, name
    else
      changeset
    end

    case Repo.update changeset do
      {:ok, user} ->
        conn
        |> put_flash(:info, gettext "Settings updated successfully")
        |> redirect(to: user_path(conn, :show, user))
      {:error, changeset} ->
        render conn, "edit.html", user: user, changeset: changeset
    end
  end
end
