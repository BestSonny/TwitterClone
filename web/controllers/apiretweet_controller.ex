defmodule App.APIRetweetController do
    use App.Web, :controller
  
    alias App.Retweet
    alias App.Tweet
    alias App.User
  
    #plug App.LoginRequired when action in [:index, :delete]
  
    def index(conn,  %{"login"=> login, "password" => password, "tweet_id" => tweet_id} = params) do
      loginconn = login(conn, params["login"], params["password"])
      current_user = loginconn.assigns[:current_user]
      try do 
        tweet = Repo.get! Tweet, params["tweet_id"]
        if tweet.user_id === current_user.id do
          #conn
          #|> put_flash(:error, gettext "You are not allowed to retweet your own tweets")
          #|> redirect(to: user_path(conn, :show, current_user.id))
          #|> halt
          render loginconn, App.APIErrorView, "index.json", status: %{status: "You are not allowed to retweet your own tweets"}
        else
          retweet_param = %{tweet_id: tweet.id, user_id: current_user.id}
          changeset = Retweet.changeset(%Retweet{}, retweet_param)
          try do 
            Repo.insert! changeset
            render loginconn, App.APIErrorView, "index.json", status: %{status: "Successfully retweeted"}
          rescue
            _ -> render loginconn, App.APIErrorView, "index.json", status: %{status: "retweets pair has already been taken"}
          end       
        end
      rescue
        _ -> render loginconn, App.APIErrorView, "index.json", status: %{status: "tweet_id #{params["tweet_id"]} does not exist"} 
      end
    end

    defp login(conn, login, password) do
        case authenticate login, password do
            {:ok, user} ->
              conn
              |> User.put_current_user(user)

            :error ->
              conn
              |> render(App.APIErrorView, "index.json", status: %{status: 11})
        end
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
end