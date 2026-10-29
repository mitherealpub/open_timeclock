defmodule TimeclockWeb.Dashboard.IndexLive do
  use TimeclockWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Read structural baseline indexes across system domains to supply totals on the gateway
    user_count = Timeclock.Accounts.User |> Ash.read!() |> Enum.count()
    project_count = Timeclock.Projects.Project |> Ash.read!() |> Enum.count()
    active_shifts = Timeclock.Scheduling.Shift |> Ash.read!() |> Enum.count()

    {:ok, 
     assign(socket, 
       user_count: user_count, 
       project_count: project_count, 
       active_shifts: active_shifts,
       page_title: "Dashboard Gateway"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-8">
      <div>
        <h1 class="text-3xl font-extrabold tracking-tight text-gray-900">Workforce Dashboard Gateway</h1>
        <p class="text-sm text-gray-500 mt-1">Welcome back. Select an operational command vector below to manage your system domains.</p>
      </div>

      <!-- Overview Metric Cards Grid Matrix -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm transition hover:shadow-md">
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wider">Identities Registered</span>
          <span class="block text-3xl font-black text-indigo-600 mt-2">{@user_count} Users</span>
        </div>
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm transition hover:shadow-md">
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wider">Operational Trackers</span>
          <span class="block text-3xl font-black text-blue-600 mt-2">{@project_count} Active Projects</span>
        </div>
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm transition hover:shadow-md">
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wider">Configured Rotations</span>
          <span class="block text-3xl font-black text-purple-600 mt-2">{@active_shifts} Shift Blocks</span>
        </div>
      </div>

      <!-- Quick Navigation Dashboard Entryway Link Array Elements -->
      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-4">
        <h2 class="text-lg font-bold text-gray-900">Operational Quick Access Shortcuts</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <.link navigate={~p"/home/terminal"} class="p-4 border border-gray-200 rounded-xl hover:bg-slate-50 transition block group shadow-xxs">
            <span class="block font-bold text-gray-900 group-hover:text-indigo-600 transition-colors">⏱️ Clocking Terminal</span>
            <span class="block text-xs text-gray-400 mt-1">Open employee punch-clock terminal inputs layer.</span>
          </.link>
          <.link navigate={~p"/admin/infrastructure"} class="p-4 border border-gray-200 rounded-xl hover:bg-slate-50 transition block group shadow-xxs">
            <span class="block font-bold text-gray-900 group-hover:text-indigo-600 transition-colors">🏢 Infrastructure Units</span>
            <span class="block text-xs text-gray-400 mt-1">Configure company profiles, branches, and addresses.</span>
          </.link>
          <.link navigate={~p"/admin/roster-planner"} class="p-4 border border-gray-200 rounded-xl hover:bg-slate-50 transition block group shadow-xxs">
            <span class="block font-bold text-gray-900 group-hover:text-indigo-600 transition-colors">🗓️ Shift Scheduler</span>
            <span class="block text-xs text-gray-400 mt-1">Assign active workforce timelines and roster slots.</span>
          </.link>
          <.link navigate={~p"/admin/system-settings"} class="p-4 border border-gray-200 rounded-xl hover:bg-slate-50 transition block group shadow-xxs">
            <span class="block font-bold text-gray-900 group-hover:text-indigo-600 transition-colors">⚙️ System Gateways</span>
            <span class="block text-xs text-gray-400 mt-1">Update encrypted global integration parameters variables.</span>
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
