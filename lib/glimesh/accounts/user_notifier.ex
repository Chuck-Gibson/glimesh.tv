defmodule Glimesh.Accounts.UserNotifier do
  @moduledoc false

  alias GlimeshWeb.Emails.Email
  alias GlimeshWeb.Emails.Mailer

  import Glimesh.Emails, only: [log_bamboo_delivery: 5]
  alias Glimesh.Emails

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_launch_update(user) do
    email = Email.user_launch_info(user)

    if Emails.email_sent?(user, subject: email.subject) do
      {:ok, :debounced}
    else
      Mailer.deliver_later(email)
      |> log_bamboo_delivery(
        user,
        "Account Update",
        "service:launch_update",
        email.subject
      )

      {:ok, %{to: email.to, body: email.text_body}}
    end
  end

  def deliver_privacy_update(user) do
    email = Email.user_privacy_update(user)

    if Emails.email_sent?(user, function: "service:privacy_update_march_2022") do
      {:ok, :debounced}
    else
      Mailer.deliver_later(email)
      |> log_bamboo_delivery(
        user,
        "Account Update",
        "service:privacy_update_march_2022",
        email.subject
      )

      {:ok, %{to: email.to, body: email.text_body}}
    end
  end

  def deliver_sub_button_enabled(user, url) do
    email = Email.user_sub_button_enabled(user, url)

    if Emails.email_sent?(user, subject: email.subject) do
      {:ok, :debounced}
    else
      Mailer.deliver_later(email)
      |> log_bamboo_delivery(
        user,
        "Account Update",
        "service:sub_button_enabled",
        email.subject
      )

      {:ok, %{to: email.to, body: email.text_body}}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    email = Email.user_confirmation_instructions(user, url)

    Mailer.deliver_later(email)
    |> log_bamboo_delivery(
      user,
      "Account Transactional",
      "user:confirmation_instructions",
      email.subject
    )

    {:ok, %{to: email.to, body: email.text_body}}
  end

  @doc """
  Deliver instructions to reset password account.
  """
  def deliver_reset_password_instructions(user, url) do
    email = Email.user_reset_password_instructions(user, url)

    Mailer.deliver_later(email)
    |> log_bamboo_delivery(
      user,
      "Account Transactional",
      "user:reset_password_instructions",
      email.subject
    )

    {:ok, %{to: email.to, body: email.text_body}}
  end

  @doc """
  Deliver instructions to update your e-mail.
  """
  def deliver_update_email_instructions(user, url) do
    email = Email.user_update_email_instructions(user, url)

    Mailer.deliver_later(email)
    |> log_bamboo_delivery(
      user,
      "Account Transactional",
      "user:update_email_instructions",
      email.subject
    )

    {:ok, %{to: email.to, body: email.text_body}}
  end

  @doc """
  Send a user report alert to an admin
  """
  def deliver_user_report_alert(reporting_user, reported_user, reason, location, notes) do
    admins = Glimesh.Accounts.list_admins()

    for admin <- admins do
      email =
        Email.user_report_alert(admin, reporting_user, reported_user, reason, location, notes)

      Mailer.deliver_later(email)
      |> log_bamboo_delivery(
        admin,
        "Admin Transactional",
        "user:user_report_alert",
        email.subject
      )
    end

    {:ok, %{}}
  end
end
