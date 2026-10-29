defmodule Timeclock.Workers.EmailDeliveryWorker do
  use Oban.Worker, queue: :mailers, max_attempts: 4

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "url" => url, "subject" => subject}}) do
    case Ash.get(Timeclock.Accounts.User, user_id) do
      {:ok, user} ->
        # Execute your existing Swoosh premailx pipeline in a background thread
        Timeclock.Mailer.Email.Update.process(user, url, subject)
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end
end
