defmodule TimeclockWeb.OnlineLive do
  use TimeclockWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    # 1. Initialize an empty streams container
    socket = stream(socket, :presences, [])

    socket =
      if connected?(socket) do
        name_param = params["name"]

        # Guard against completely blank or empty parameter targets
        if name_param && String.trim(name_param) != "" do
          # Track the current connection context inside your Phoenix Presence registry tracker
          TimeclockWeb.Presence.track_user(name_param, %{id: name_param})
        end

        # Subscribe to realtime tracking pubsub event broadcast layers
        TimeclockWeb.Presence.subscribe()

        # 2. Extract active states and transform the raw map into a stream-friendly list
        presence_list = 
          TimeclockWeb.Presence.list_online_users()
          |> Enum.map(fn {user_key, %{metas: metas}} ->
            # Map into objects with explicit top-level :id attributes for the DOM engine
            %{id: user_key, name: user_key, metas: metas}
          end)

        stream(socket, :presences, presence_list)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-2xl mx-auto space-y-4">
      <div class="border-b pb-3">
        <h1 class="text-2xl font-black tracking-tight text-slate-900">Live Presence Directory</h1>
        <p class="text-xs text-slate-500 mt-0.5">Real-time terminal visibility monitoring current user system interactions.</p>
      </div>

      <ul id="online_users" phx-update="stream" class="divide-y divide-slate-100 bg-white border rounded-xl overflow-hidden shadow-xs">
        <li 
          :for={{dom_id, user} <- @streams.presences} 
          id={dom_id}
          class="p-4 flex items-center justify-between hover:bg-slate-50/50 transition animate-fadeIn"
        >
          <div class="flex items-center gap-3">
            <span class="h-2 w-2 rounded-full bg-emerald-500 animate-pulse shrink-0"></span>
            <span class="font-mono text-sm font-semibold text-slate-800">{user.name}</span>
          </div>
          <span class="text-xs font-bold font-mono px-2.5 py-0.5 bg-slate-100 border border-slate-200 text-slate-600 rounded-md">
            Active Devices: {Enum.count(user.metas)}
          </span>
        </li>
        <li :if={Enum.empty?(@streams.presences)} class="p-8 text-center text-xs text-slate-400 font-medium">
          No monitoring profiles currently active in this workspace view sector.
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_info({TimeclockWeb.Presence, {:join, {user_key, %{metas: metas}}}}, socket) do
    # Normalize join events into top-level id structures
    payload = %{id: user_key, name: user_key, metas: metas}
    {:noreply, stream_insert(socket, :presences, payload)}
  end

  @impl true
  def handle_info({TimeclockWeb.Presence, {:leave, {user_key, %{metas: metas}}}}, socket) do
    payload = %{id: user_key, name: user_key, metas: metas}

    if metas == [] do
      {:noreply, stream_delete(socket, :presences, payload)}
    else
      {:noreply, stream_insert(socket, :presences, payload)}
    end
  end
end
