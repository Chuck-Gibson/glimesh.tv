defmodule Glimesh.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glimesh.Accounts` context.
  """

  def unique_user_username, do: "user#{System.unique_integer([:positive])}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def subcategory_fixture(attrs \\ %{}) do
    %Glimesh.Streams.Category{id: cat_id} = Glimesh.ChannelCategories.get_category("gaming")

    {:ok, subcat} =
      Glimesh.ChannelCategories.create_subcategory(
        Map.merge(
          %{
            category_id: cat_id,
            name: "World of Warcraft"
          },
          attrs
        )
      )

    subcat
  end

  def tag_fixture(tag_attrs \\ %{}) do
    %Glimesh.Streams.Category{id: cat_id} = Glimesh.ChannelCategories.get_category("gaming")

    {:ok, tag} =
      Glimesh.ChannelCategories.create_tag(
        Map.merge(
          %{
            category_id: cat_id,
            name: "Chill Stream"
          },
          tag_attrs
        )
      )

    tag
  end

  def streamer_fixture(user_attrs \\ %{}, channel_attrs \\ %{}) do
    # Users need to be confirmed & can_stream to be a streamer
    streamer =
      user_fixture(user_attrs)
      |> Ecto.Changeset.change(%{
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        can_stream: true
      })
      |> Glimesh.Repo.update!()

    {:ok, _} =
      Glimesh.Streams.create_channel(
        streamer,
        Map.merge(
          %{category_id: Enum.at(Glimesh.ChannelCategories.list_categories(), 0).id},
          channel_attrs
        )
      )

    Glimesh.Accounts.get_user!(streamer.id)
    |> Glimesh.Repo.preload(channel: [:category, :subcategory, :tags])
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: unique_user_username(),
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Glimesh.Accounts.register_user()

    user
  end

  def change_inserted_at_for_user(%Glimesh.Accounts.User{} = user, new_inserted_at) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.force_change(:inserted_at, new_inserted_at)
    |> Glimesh.Repo.update!()

    Glimesh.Accounts.get_user!(user.id)
    |> Glimesh.Repo.preload(channel: [:category, :subcategory, :tags])
  end

  def change_user_banned_status(%Glimesh.Accounts.User{} = user, new_status) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.force_change(:is_banned, new_status)
    |> Glimesh.Repo.update()

    Glimesh.Accounts.get_user!(user.id)
    |> Glimesh.Repo.preload(channel: [:category, :subcategory, :tags])
  end

  def admin_fixture(_attrs \\ %{}) do
    user_fixture(%{is_admin: true})
  end

  def gct_fixture(attrs \\ %{}) do
    user =
      attrs
      |> Enum.into(%{
        is_gct: true
      })
      |> user_fixture()

    user
  end

  def banned_fixture(_attrs \\ %{}) do
    user_fixture(%{is_banned: true})
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
