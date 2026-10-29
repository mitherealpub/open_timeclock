defmodule TimeclockWeb.Presence do
  @moduledoc """
  Provides real-time presence tracking for users within the Timeclock application.

  Utilizes Phoenix.Presence under the hood to manage stateful synchronization
  of connected sessions across cluster nodes.
  """
  use Phoenix.Presence,
    otp_app: :timeclock,
    pubsub_server: Timeclock.PubSub

  @topic "online_users:presence"

  @doc """
  Registers and tracks an active user identity connection within the Presence channel.
  """
  def track_user(user_name, meta) when is_binary(user_name) and is_map(meta) do
    track(self(), @topic, user_name, meta)
  end

  @doc """
  Subscribes the calling LiveView process to presence join/leave broadcast events.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Timeclock.PubSub, @topic)
  end

  @doc """
  Lists all currently active online users and transforms the tracking state 
  into a streamlined list map format compatible with LiveView stream payloads.
  """
  def list_online_users do
    list(@topic)
  end
end
