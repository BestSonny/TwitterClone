defmodule App.APISignupController do
    use App.Web, :controller

    alias App.User

    import Ecto.Changeset

    plug App.RedirectAuthenticated
    def index(conn, %{"login" =>login, "name" => name, "password" => password, "password_confirmation" => password_confirmation, "email"=> email} = user_params) do
        #conn
        #|> text("I see, #{name} is #{age} years old!")
        #changeset = User.changeset(%User{})
        #render conn, "index.json", changeset: changeset
        changeset = User.changeset(%User{}, user_params) |> User.with_password_hash
        changeset = put_change(changeset, :profile_picture, "default_profile.png")
        case Repo.insert changeset do
          {:ok, user} ->
            conn
            |> User.put_current_user(user)
            #|> put_flash(:info, gettext "Successfully created user account")
            #|> redirect(to: user_path(conn, :show, user))
            render(conn, "index.json", status: %{status: "signup successful"})
          {:error, changeset} ->
            render conn, "index.json", status: %{status: "signup failed"}
        end
    end

    def create(conn, %{"user" => user_params}) do
      changeset = User.changeset(%User{}, user_params) |> User.with_password_hash
      changeset = put_change(changeset, :profile_picture, "default_profile.png")
      case Repo.insert changeset do
        {:ok, user} ->
          conn
          |> User.put_current_user(user)
          |> put_flash(:info, gettext "Successfully created user account")
          |> redirect(to: user_path(conn, :show, user))
        {:error, changeset} ->
          render conn, "index.json", changeset: changeset
      end
    end
  end
