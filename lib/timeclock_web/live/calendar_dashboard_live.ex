defmodule TimeclockWeb.CalendarDashboardLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    events = fetch_events()
    groups = Ash.read!(Timeclock.Calendar.Group)
    group_options = Enum.map(groups, &{&1.name, &1.id})

    form = Timeclock.Calendar.Event |> AshPhoenix.Form.for_create(:create, params: %{"type" => %{}}) |> to_form()
    {:ok, assign(socket, events: events, group_options: group_options, form: form)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params) |> to_form())}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Event logged.") |> assign(events: fetch_events(), form: reset_form())}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Ash.get(Timeclock.Calendar.Event, id) do
      {:ok, item} -> Ash.destroy!(item); {:noreply, socket |> put_flash(:info, "Event purged.") |> assign(events: fetch_events())}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Error.")}
    end
  end

  defp fetch_events, do: Timeclock.Calendar.Event |> Ash.Query.load([:group]) |> Ash.read!()
  defp reset_form, do: Timeclock.Calendar.Event |> AshPhoenix.Form.for_create(:create, params: %{"type" => %{}}) |> to_form()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Institutional Event Matrix</h1>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit">
          <h2 class="text-lg font-bold text-gray-900 mb-4">Publish Event</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div><.input field={@form[:name]} type="text" placeholder="Annual Strategic Alignment" class="w-full text-sm" /></div>
            <div><.input field={@form[:group_id]} type="select" options={@group_options} prompt="Audience Scope Group" class="w-full text-sm" /></div>
            <div class="grid grid-cols-2 gap-4">
              <div><.input field={@form[:date]} type="date" class="w-full text-sm" /></div>
              <div><.input field={@form[:valid_to]} type="date" class="w-full text-sm" /></div>
            </div>
            <div><.input field={@form[:recurring_mode]} type="text" placeholder="Yearly / None" class="w-full text-sm" /></div>
            <div class="border border-indigo-100 bg-indigo-50/20 p-4 rounded-xl space-y-3">
              <span class="text-xs font-bold text-indigo-900 uppercase block">Classification Embed</span>
              <.inputs_for :let={sub} field={@form[:type]}>
                <div><.input field={sub[:name]} type="text" placeholder="Holiday Code Name" class="w-full text-xs bg-white" /></div>
                <div><.input field={sub[:value]} type="number" placeholder="Weight Factor ID" class="w-full text-xs bg-white" /></div>
              </.inputs_for>
            </div>
            <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-sm">Deploy Event</button>
          </.form>
        </div>
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Calendar Event Logging Board</h2>
          <table class="min-w-full divide-y divide-gray-200 text-sm text-left">
            <thead>
              <tr class="text-gray-500 bg-gray-50">
                <th class="p-3">Event Frame</th>
                <th class="p-3">Group Target</th>
                <th class="p-3">Duration Bounds</th>
                <th class="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr :for={e <- @events} id={"evt-#{e.id}"}>
                <td class="p-3">
                  <span class="font-bold text-gray-900 block">{e.name}</span>
                  <div :if={e.type} class="text-[10px] text-gray-400 mt-0.5">¼️ Name: {e.type.name} | Val: {e.type.value}</div>
                </td>
                <td class="p-3"><span class="px-2 py-0.5 text-xs bg-blue-50 text-blue-800 rounded border border-blue-200 font-medium">👥 {if e.group, do: e.group.name, default: "Global"}</span></td>
                <td class="p-3 text-xs text-gray-500 font-mono">{e.date} → {e.valid_to}</td>
                <td class="p-3 text-right"><button phx-click="delete" phx-value-id={e.id} class="text-red-600 font-semibold text-xs hover:underline">Purge</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end
