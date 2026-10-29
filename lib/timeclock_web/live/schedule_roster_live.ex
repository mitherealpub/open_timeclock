defmodule TimeclockWeb.ScheduleRosterLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    schedules = fetch_schedules()
    shifts = Ash.read!(Timeclock.Scheduling.Shift)
    users = Ash.read!(Timeclock.Accounts.User, load: [:account])

    shift_options = Enum.map(shifts, &{&1.name, &1.id})
    user_options = Enum.map(users, &{if(&1.account, do: "#{&1.account.first_name} #{&1.account.last_name}", do: &1.email), &1.id})

    form = Timeclock.Scheduling.Schedule |> AshPhoenix.Form.for_create(:create) |> to_form()
    {:ok, assign(socket, schedules: schedules, shift_options: shift_options, user_options: user_options, form: form)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params) |> to_form())}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Roster updated.") |> assign(schedules: fetch_schedules(), form: reset_form())}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Ash.get(Timeclock.Scheduling.Schedule, id) do
      {:ok, entry} -> Ash.destroy!(entry); {:noreply, socket |> put_flash(:info, "Shift removed.") |> assign(schedules: fetch_schedules())}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Not found.")}
    end
  end

  defp fetch_schedules, do: Timeclock.Scheduling.Schedule |> Ash.Query.load([:user, :shift]) |> Ash.read!()
  defp reset_form, do: Timeclock.Scheduling.Schedule |> AshPhoenix.Form.for_create(:create) |> to_form()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Roster Shift Scheduler</h1>
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit">
          <h2 class="text-lg font-bold text-gray-900 mb-4">Allocate Shift</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div></div>
            <div><.input field={@form[:shift_id]} type="select" options={@shift_options} prompt="Select Shift Rule" class="w-full text-sm" /></div>
            <div class="grid grid-cols-2 gap-4">
              <div><.input field={@form[:start_time]} type="datetime-local" class="w-full text-sm" /></div>
              <div><.input field={@form[:end_time]} type="datetime-local" class="w-full text-sm" /></div>
            </div>
            <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-sm">Commit Shift Allocation</button>
          </.form>
        </div>
        <div class="xl:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Active Roster Ledger</h2>
          <table class="min-w-full divide-y divide-gray-200 text-sm text-left">
            <thead>
              <tr class="text-gray-500 bg-gray-50">
                <th class="p-3">Employee Context</th>
                <th class="p-3">Shift Parameter Map</th>
                <th class="p-3">Timeframe Bounds</th>
                <th class="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr :for={s <- @schedules} id={"sched-#{s.id}"}>
                <td class="p-3 font-medium">{if s.user, do: s.user.email, default: "Floating"}</td>
                <td class="p-3"><span class="px-2 py-0.5 text-xs bg-purple-50 text-purple-700 border border-purple-200 rounded font-mono font-bold">{if s.shift, do: s.shift.name, default: "Custom"}</span></td>
                <td class="p-3 text-xs text-gray-500 font-mono">{Calendar.strftime(s.start_time, "%m-%d %H:%M")} → {Calendar.strftime(s.end_time, "%m-%d %H:%M")}</td>
                <td class="p-3 text-right"><button phx-click="delete" phx-value-id={s.id} class="text-red-600 text-xs font-semibold hover:underline">Revoke</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
