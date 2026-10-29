defmodule TimeclockWeb.System.SetupLive do
  use TimeclockWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Check current system states to verify if bootstrap variables need deployment initialization
    has_orgs = Timeclock.Organizations.Organization |> Ash.read!() |> Enum.any?()
    has_shifts = Timeclock.Scheduling.Shift |> Ash.read!() |> Enum.any?()
    has_statuses = Timeclock.System.Status |> Ash.read!() |> Enum.any?()

    {:ok, 
     assign(socket, 
       has_orgs: has_orgs, 
       has_shifts: has_shifts, 
       has_statuses: has_statuses,
       page_title: "System Orchestration Setup"
     )}
  end

  @impl true
  def handle_event("bootstrap_defaults", _params, socket) do
    # 1. Initialize Global System Configuration Singleton
    _settings = 
      case Ash.read!(Timeclock.System.Settings) do
        [] -> Ash.create!(Timeclock.System.Settings, :init)
        [record | _] -> record
      end

    # 2. Seed Default Standard Core Status Codes if empty
    if !socket.assigns.has_statuses do
      Ash.create!(Timeclock.System.Status, %{name: "Present / On-Duty", presence_status: "present", paid_time_status: "regular", color: "emerald"})
      Ash.create!(Timeclock.System.Status, %{name: "Absent / Sick Leave", presence_status: "absent", paid_time_status: "sick", color: "rose"})
    end

    # 3. Trigger Your Application Setup Runtime Setup Configuration Pipeline Hook
    # Maps directly onto your Timeclock.System.Setup module logic
    _output_params = Timeclock.System.Setup.run(%{"bootstrapped_at" => DateTime.utc_now()})

    {:noreply,
     socket
     |> put_flash(:info, "System variables and settings matrices initialized successfully.")
     |> assign(has_statuses: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto space-y-6">
      <div>
        <h1 class="text-3xl font-extrabold tracking-tight text-gray-900">System Initial Setup Wizard</h1>
        <p class="text-sm text-gray-500 mt-1">Verify foundational component parameters and instantiate base domain directories.</p>
      </div>

      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-6">
        <h3 class="text-base font-bold text-gray-900 border-b pb-2">Platform Readiness Inspection Matrix</h3>
        
        <div class="space-y-3">
          <div class="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-gray-150">
            <div>
              <span class="block font-semibold text-sm text-gray-800">Organization Infrastructure Layout</span>
              <span class="text-xs text-gray-400">Verifies if top-level root organization registries are present.</span>
            </div>
            <span class={"text-xs font-bold font-mono uppercase px-2 py-0.5 rounded #{if @has_orgs, do: 'bg-green-100 text-green-800', do: 'bg-amber-100 text-amber-800'}"}>
              {if @has_orgs, do: "Ready", default: "Pending Configuration"}
            </span>
          </div>

          <div class="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-gray-150">
            <div>
              <span class="block font-semibold text-sm text-gray-800">Rotational Shift Definitions Matrix</span>
              <span class="text-xs text-gray-400">Verifies presence of workforce work hour threshold boundaries.</span>
            </div>
            <span class={"text-xs font-bold font-mono uppercase px-2 py-0.5 rounded #{if @has_shifts, do: 'bg-green-100 text-green-800', do: 'bg-amber-100 text-amber-800'}"}>
              {if @has_shifts, do: "Ready", default: "Pending Configuration"}
            </span>
          </div>

          <div class="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-gray-150">
            <div>
              <span class="block font-semibold text-sm text-gray-800">Status & Marker Codes Core Registry</span>
              <span class="text-xs text-gray-400">Verifies presence of functional punch tracking markers (e.g., Present, Absent).</span>
            </div>
            <span class={"text-xs font-bold font-mono uppercase px-2 py-0.5 rounded #{if @has_statuses, do: 'bg-green-100 text-green-800', do: 'bg-amber-100 text-amber-800'}"}>
              {if @has_statuses, do: "Populated", default: "Empty"}
            </span>
          </div>
        </div>

        <div class="pt-4 border-t flex items-center justify-between gap-4">
          <p class="text-xs text-slate-400 max-w-lg">
            Clicking bootstrap executes setup checks, runs configuration overrides hooks, instantiates base system parameter singletons, and maps default code records safely.
          </p>
          <button 
            phx-click="bootstrap_defaults"
            class="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-5 rounded-lg shadow-sm text-sm tracking-wide transition shrink-0"
          >
            Bootstrap System Defaults
          </button>
        </div>
      </div>
    </div>
    """
  end
end
