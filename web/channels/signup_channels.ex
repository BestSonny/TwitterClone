defmodule App.SignupChannel do
  use App.Web, :channel
  alias App.User
  import Ecto.Changeset
  require Logger

  def join("signup", _params, socket) do
    send self(), {:sign_up, _params}
    {:ok, socket}
  end

  def handle_info({:sign_up, _params}, socket), do: socket |> sign_up( _params)

  defp sign_up(socket,  _params) do
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
  
end
