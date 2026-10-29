defmodule TimeclockWeb.ClockingTerminalLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    users = Ash.read!(Timeclock.Accounts.User, load: [:account])
    definitions = Ash.read!(Timeclock.Clocking.Definition)
    statuses = Ash.read!(Timeclock.System.Status)

    user_options = Enum.map(users, &{if(&1.account, do: "#{&1.account.first_name} #{&1.account.last_name}", do: &1.email), &1.id})
    definition_options = Enum.map(definitions, &{&1.name, &1.id})
    status_options = Enum.map(statuses, &{&1.name, &1.id})

    form =
      Timeclock.Clocking.Clocking
      |> AshPhoenix.Form.for_create(:insert_from_web, params: %{"geolocation" => %{}})
      |> to_form()

    {:ok, assign(socket, clockings: fetch_clockings(), user_options: user_options, definition_options: definition_options, status_options: status_options, form: form, has_geo: false)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    params = Map.put_new(params, "has_geo_location", "false")
    form = AshPhoenix.Form.validate(socket.assigns.form, params) |> to_form()
    {:noreply, assign(socket, form: form, has_geo: params["has_geo_location"] == "true")}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    params = params |> Map.put_new("has_geo_location", "false") |> Map.put("timestamp", DateTime.utc_now() |> DateTime.to_iso8601())
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Punch captured.") |> assign(clockings: fetch_clockings(), form: reset_form(), has_geo: false)}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  defp fetch_clockings, do: Timeclock.Clocking.Clocking |> Ash.Query.load([:user, :definition, :status]) |> Ash.Query.limit(10) |> Ash.read!()
  defp reset_form, do: Timeclock.Clocking.Clocking |> AshPhoenix.Form.for_create(:insert_from_web, params: %{"geolocation" => %{}}) |> to_form()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Workforce Kiosk Terminal</h1>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Record Attendance</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-gray-500 uppercase">Employee</label>
              <.input field={@form[:user_id]} type="select" options={@user_options} prompt="Select profile..." class="mt-1 block w-full rounded border-gray-300 text-sm" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-500 uppercase">Punch Matrix</label>
              <.input field={@form[:definition_id]} type="select" options={@definition_options} prompt="Select vector..." class="mt-1 block w-full rounded border-gray-300 text-sm" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-500 uppercase">Metric Status</label>
              <.input field={@form[:status_id]} type="select" options={@status_options} prompt="Select status..." class="mt-1 block w-full rounded border-gray-300 text-sm" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-500 uppercase">Comment</label>
              <.input field={@form[:comment]} type="text" placeholder="Shift notes..." class="mt-1 block w-full rounded border-gray-300 text-sm" />
            </div>
            <div class="p-3 bg-gray-50 rounded-lg space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-xs font-semibold text-gray-700 uppercase">Geolocate</span>
                <.input field={@form[:has_geo_location]} type="checkbox" class="rounded text-indigo-600" />
              </div>
              <div :if={@has_geo} class="grid grid-cols-2 gap-2 pt-2 border-t border-gray-200">
                <.inputs_for :let={geo} field={@form[:geolocation]}>
                  <div><.input field={geo[:latitude]} type="number" step="0.0001" placeholder="Lat" class="w-full text-xs" /></div>
                  <div><.input field={geo[:longitude]} type="number" step="0.0001" placeholder="Lng" class="w-full text-xs" /></div>
                </.inputs_for>
              </div>
            </div>
            <button type="submit" class="w-full bg-indigo-600 text-white font-semibold py-2 rounded shadow hover:bg-indigo-700 transition">Log Clocking</button>
          </.form>
        </div>
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Live Activity Streams</h2>
          <table class="min-w-full divide-y divide-gray-200 text-sm text-left">
            <thead>
              <tr class="text-gray-500 font-medium bg-gray-50">
                <th class="p-3">Identity</th>
                <th class="p-3">Action</th>
                <th class="p-3">Status</th>
                <th class="p-3 text-right">Horizon</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr :for={c <- @clockings} id={"clocking-row-#{c.id}"}>
                <td class="p-3 font-medium">{if c.user, do: c.user.email, default: "System"}</td>
                <td class="p-3">{if c.definition, do: c.definition.name, default: "Punch"}</td>
                <td class="p-3"><span class="px-2 py-0.5 text-xs bg-blue-100 rounded text-blue-800">{if c.status, do: c.status.name, default: "Default"}</span></td>
                <td class="p-3 text-right font-mono text-xs text-gray-400">{NaiveDateTime.to_time(c.created_at)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
