defmodule TimeclockWeb.ScheduleGanttLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    schedules = fetch_schedules()
    shifts = Ash.read!(Timeclock.Scheduling.Shift)
    users = Ash.read!(Timeclock.Accounts.User, load: [:account])

    shift_options = Enum.map(shifts, &{&1.name, &1.id})
    user_options = Enum.map(users, &{if(&1.account, do: "#{&1.account.first_name} #{&1.account.last_name}", do: &1.email), &1.id})
    hours_timeline = Enum.map(0..23, &String.pad_leading("#{&1}:00", 5, "0"))

    {:ok, assign(socket, schedules: schedules, user_options: user_options, shift_options: shift_options, hours_timeline: hours_timeline, form: nil, selected_schedule: nil)}
  end

  @impl true
  def handle_event("select_schedule", %{"id" => id}, socket) do
    schedule = Timeclock.Scheduling.Schedule |> Ash.Query.load([:user, :shift]) |> Ash.get!(id)
    form = schedule |> AshPhoenix.Form.for_update(:update) |> to_form()
    {:noreply, assign(socket, selected_schedule: schedule, form: form)}
  end

  @impl true
  def handle_event("close_editor", _params, socket), do: {:noreply, assign(socket, selected_schedule: nil, form: nil)}

  @impl true
  def handle_event("validate", %{"form" => form_params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, form_params) |> to_form())}
  end

  @impl true
  def handle_event("save", %{"form" => form_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Roster timeframe updated.") |> assign(schedules: fetch_schedules(), selected_schedule: nil, form: nil)}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("delete_schedule", %{"id" => id}, socket) do
    case Ash.get(Timeclock.Scheduling.Schedule, id) do
      {:ok, entry} -> Ash.destroy!(entry); {:noreply, socket |> put_flash(:info, "Deleted.") |> assign(schedules: fetch_schedules(), selected_schedule: nil, form: nil)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Error.")}
    end
  end

  defp fetch_schedules, do: Timeclock.Scheduling.Schedule |> Ash.Query.load([:user, :shift]) |> Ash.read!()

  defp calculate_grid_positions(start_time, end_time) do
    start_hour = start_time.hour + (start_time.minute / 60.0)
    end_hour = end_time.hour + (end_time.minute / 60.0)
    col_start = max(1, min(49, round(start_hour * 2) + 1))
    col_end = max(col_start + 1, min(49, round(end_hour * 2) + 1))
    "grid-column-start: #{col_start}; grid-column-end: #{col_end};"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Timeline Gantt Planner</h1>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col space-y-4">
          <div class="border border-gray-200 rounded-lg overflow-x-auto min-w-[600px] bg-slate-50/50">
            <div class="grid grid-cols-24 border-b border-gray-200 bg-gray-100 font-mono text-[10px] text-gray-500 font-bold text-center divide-x divide-gray-200">
              <div :for={hour <- @hours_timeline} class="py-2 px-1 truncate">{hour}</div>
            </div>
            <div class="divide-y divide-gray-200 min-h-[300px]">
              <div :for={schedule <- @schedules} class="relative p-2 h-14 bg-white flex items-center" id={"gantt-row-#{schedule.id}"}>
                <div class="absolute left-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 pointer-events-none z-0">
                  {if schedule.user, do: String.take(schedule.user.email, 15) <> "...", default: "Floating Slot"}
                </div>
                <button
                  type="button"
                  phx-click="select_schedule"
                  phx-value-id={schedule.id}
                  style={calculate_grid_positions(schedule.start_time, schedule.end_time)}
                  class={"w-full h-9 rounded-lg shadow-sm border text-left p-2 flex flex-col justify-center relative z-10 transition duration-150 group #{if @selected_schedule && @selected_schedule.id == schedule.id, do: 'bg-indigo-600 border-indigo-700 text-white', default: 'bg-indigo-50 border-indigo-200 text-indigo-900 hover:bg-indigo-100'}"}
                >
                  <span class="block text-[10px] font-black uppercase tracking-tight truncate">{if schedule.shift, do: schedule.shift.name, default: "Custom Period"}</span>
                  <span class="block text-[8px] font-mono mt-0.5 truncate">{Calendar.strftime(schedule.start_time, "%H:%M")} - {Calendar.strftime(schedule.end_time, "%H:%M")}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
        <div class="lg:col-span-1 bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit space-y-4">
          <h2 class="text-lg font-bold text-gray-900 border-b pb-2">Workspace Editor</h2>
          <div :if={@selected_schedule && @form} class="space-y-4">
            <div class="p-3 bg-slate-50 border rounded-lg text-xs font-semibold">User: {@selected_schedule.user.email}</div>
            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
              <div><.input field={@form[:shift_id]} type="select" options={@shift_options} prompt="Override Shift Type" class="w-full text-sm" /></div>
              <div><.input field={@form[:start_time]} type="datetime-local" class="w-full text-sm" /></div>
              <div><.input field={@form[:end_time]} type="datetime-local" class="w-full text-sm" /></div>
              <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-sm">Save Changes</button>
              <button type="button" phx-click="delete_schedule" phx-value-id={@selected_schedule.id} data-confirm="Delete shift?" class="w-full bg-red-50 text-red-700 border border-red-200 font-bold py-2 rounded text-sm">Delete</button>
            </.form>
          </div>
          <div :if={!@selected_schedule} class="py-16 text-center text-sm text-gray-400 italic">Select a timeline bar above to open the modification editor.</div>
        </div>
      </div>
    </div>
    """
  end
end
