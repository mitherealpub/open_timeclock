defmodule TimeclockWeb.ScheduleGanttLive do
  use TimeclockWeb, :live_view

  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    # Fetch structural collections
    schedules = fetch_schedules()
    shifts = Ash.read!(Timeclock.Scheduling.Shift)
    users = Ash.read!(Timeclock.Accounts.User, load: [:account])

    shift_options = Enum.map(shifts, &{&1.name, &1.id})
    user_options = Enum.map(users, fn u ->
      label = if u.account, do: "#{u.account.first_name} #{u.account.last_name} (#{u.email})", do: u.email
      {label, u.id}
    end)

    # Base operational timeline parameters (Defaulting to a 24-hour visualization perspective)
    hours_timeline = Enum.map(0..23, &String.pad_leading("#{&1}:00", 5, "0"))

    {:ok,
     assign(socket,
       schedules: schedules,
       user_options: user_options,
       shift_options: shift_options,
       hours_timeline: hours_timeline,
       form: nil,
       selected_schedule: nil
     )}
  end

  @impl true
  def handle_event("select_schedule", %{"id" => id}, socket) do
    schedule = 
      Timeclock.Scheduling.Schedule
      |> Ash.Query.load([:user, :shift])
      |> Ash.get!(id)

    form =
      schedule
      |> AshPhoenix.Form.for_update(:update, api: Timeclock.Scheduling)
      |> to_form()

    {:noreply, assign(socket, selected_schedule: schedule, form: form)}
  end

  @impl true
  def handle_event("close_editor", _params, socket) do
    {:noreply, assign(socket, selected_schedule: nil, form: nil)}
  end

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(form_params)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, _updated_schedule} ->
        {:noreply,
         socket
         |> put_flash(:info, "Roster timeframe metrics updated successfully.")
         |> assign(schedules: fetch_schedules(), selected_schedule: nil, form: nil)}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("delete_schedule", %{"id" => id}, socket) do
    case Ash.get(Timeclock.Scheduling.Schedule, id) do
      {:ok, entry} ->
        Ash.destroy!(entry)
        {:noreply, 
         socket 
         |> put_flash(:info, "Roster block successfully deleted.") 
         |> assign(schedules: fetch_schedules(), selected_schedule: nil, form: nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Schedule target record not found.")}
    end
  end

  defp fetch_schedules do
    Timeclock.Scheduling.Schedule
    |> Ash.Query.load([:user, :shift])
    |> Ash.read!()
  end

  # Internal presentation helpers computing visual sizing values for Gantt segments
  defp calculate_grid_positions(start_time, end_time) do
    start_hour = start_time.hour + (start_time.minute / 60.0)
    end_hour = end_time.hour + (end_time.minute / 60.0)
    
    # Calculate span offset metrics mapping into 24 column grid structures cleanly
    # Note: Adding a 1-based offset configuration bound to feed native grid-column spans
    col_start = round(start_hour * 2) + 1
    col_end = round(end_hour * 2) + 1

    # Clamp bounds securely to guarantee layouts do not overflow container envelopes
    col_start = max(1, min(49, col_start))
    col_end = max(col_start + 1, min(49, col_end))

    "grid-column-start: #{col_start}; grid-column-end: #{col_end};"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <div>
        <h1 class="text-3xl font-extrabold tracking-tight text-gray-900">Timeline Gantt Planner</h1>
        <p class="text-sm text-gray-500 mt-1">Visualize alignment scopes across personnel files and update timeframes instantly.</p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Gantt Chart Stream Component Section -->
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col space-y-4">
          <h2 class="text-lg font-bold text-gray-900">Workforce Operational Timeline Grid</h2>
          
          <div class="border border-gray-200 rounded-lg overflow-x-auto min-w-[600px] bg-slate-50/50">
            <!-- Timeline Chart Headers Segment -->
            <div class="grid grid-cols-24 border-b border-gray-200 bg-gray-100 font-mono text-[10px] text-gray-500 font-bold text-center divide-x divide-gray-200">
              <div :for={hour <- @hours_timeline} class="py-2 px-1 truncate">
                {hour}
              </div>
            </div>

            <!-- Gantt Content Rows -->
            <div class="divide-y divide-gray-200 min-h-[300px]">
              <div :for={schedule <- @schedules} class="relative p-2 h-14 bg-white flex items-center">
                <!-- Row Background Label Hint -->
                <div class="absolute left-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 pointer-events-none z-0">
                  {if schedule.user, do: String.take(schedule.user.email, 15) <> "...", default: "Floating Slot"}
                </div>

                <!-- Floating Gantt Block Element Segment -->
                <button
                  type="button"
                  phx-click="select_schedule"
                  phx-value-id={schedule.id}
                  style={calculate_grid_positions(schedule.start_time, schedule.end_time)}
                  class={"w-full h-9 rounded-lg shadow-sm border text-left p-2 flex flex-col justify-center relative z-10 hover:scale-[1.01] active:scale-[0.99] transition duration-150 group #{if @selected_schedule && @selected_schedule.id == schedule.id, do: 'bg-indigo-600 border-indigo-700 text-white', default: 'bg-indigo-50 border-indigo-200 text-indigo-900 hover:bg-indigo-100'}"}
                >
                  <span class="block text-[10px] font-black uppercase tracking-tight truncate">
                    {if schedule.shift, do: schedule.shift.name, default: "Custom Period"}
                  </span>
                  <span class={"block text-[8px] font-mono mt-0.5 truncate #{if @selected_schedule && @selected_schedule.id == schedule.id, do: 'text-indigo-200', default: 'text-indigo-500'}"}>
                    {Calendar.strftime(schedule.start_time, "%H:%M")} - {Calendar.strftime(schedule.end_time, "%H:%M")}
                  </span>
                </button>
              </div>

              <div :if={Enum.empty?(@schedules)} class="py-16 text-center text-sm text-gray-400">
                No scheduled timeline roster blocks tracked in this visualization thread context yet.
              </div>
            </div>
          </div>
          <p class="text-xxs text-gray-400 italic">💡 Operational Guide: Click on any active floating Gantt chart timeline block above to populate modifying parameters inside the workspace editor panel.</p>
        </div>

        <!-- Sidebar Layout Column: Timeframe Modification Editor Panel -->
        <div class="lg:col-span-1 bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit space-y-4">
          <div class="flex items-center justify-between border-b pb-2">
            <h2 class="text-lg font-bold text-gray-900">Workspace Editor</h2>
            <button :if={@selected_schedule} type="button" phx-click="close_editor" class="text-xs text-gray-400 hover:text-gray-600 uppercase font-bold tracking-wider">Cancel</button>
          </div>

          <div :if={@selected_schedule && @form} class="space-y-4 animate fadeIn">
            <div class="p-3 bg-slate-50 border border-slate-200 rounded-lg text-xs space-y-1">
              <p class="text-gray-500 font-bold uppercase tracking-wider text-[10px]">Active Track Target</p>
              <p class="font-semibold text-gray-800">{@selected_schedule.user.email}</p>
            </div>

            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
              <div>
                <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Shift Rule Template Override</label>
                <.input field={@form[:shift_id]} type="select" options={@shift_options} prompt="Choose shift parameter map..." class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
              </div>

              <div>
                <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Adjustment Window Start</label>
                <.input field={@form[:start_time]} type="datetime-local" class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
              </div>

              <div>
                <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Adjustment Window End</label>
                <.input field={@form[:end_time]} type="datetime-local" class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
              </div>

              <div class="grid grid-cols-1 gap-2 pt-2 border-t">
                <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-sm hover:bg-indigo-700 transition shadow-sm">
                  Commit Timeframe Metrics
                </button>
                <button 
                  type="button" 
                  phx-click="delete_schedule" 
                  phx-value-id={@selected_schedule.id}
                  data-confirm="Permanently strike out this shift block from corporate rosters?"
                  class="w-full bg-red-50 text-red-700 border border-red-200 font-bold py-2 rounded text-sm hover:bg-red-100 transition"
                >
                  Void Roster Record
                </button>
              </div>
            </.form>
