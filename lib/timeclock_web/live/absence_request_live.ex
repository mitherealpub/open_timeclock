defmodule TimeclockWeb.AbsenceRequestLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    # Fetch lists from underlying structural data layers
    absences = fetch_user_absences(socket.assigns.current_user)
    definitions = Ash.read!(Timeclock.Absences.Definition)

    definition_options = Enum.map(definitions, &{&1.name, &1.id})

    # Prepare an initial create form configuration passing structural defaults
    form =
      Timeclock.Absences.Absence
      |> AshPhoenix.Form.for_create(:create)
      |> to_form()

    {:ok,
     assign(socket,
       absences: absences,
       definition_options: definition_options,
       form: form,
       page_title: "Time-Off Requests"
     )}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(params)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    # Inject current user ID parameters to fulfill user_id structural constraints natively
    params = Map.put(params, "user_id", socket.assigns.current_user.id)

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _absence} ->
        {:noreply,
         socket
         |> put_flash(:info, "Time-off request filed successfully.")
         |> assign(absences: fetch_user_absences(socket.assigns.current_user), form: reset_form())}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("cancel_request", %{"id" => id}, socket) do
    case Ash.get(Timeclock.Absences.Absence, id) do
      {:ok, record} ->
        # Soft remove or purge record following validation rule checks
        Ash.destroy!(record)
        {:noreply, socket |> put_flash(:info, "Request pulled successfully.") |> assign(absences: fetch_user_absences(socket.assigns.current_user))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Target entry not found.")}
    end
  end

  defp fetch_user_absences(current_user) do
    Timeclock.Absences.Absence
    |> Ash.Query.filter(user_id == ^current_user.id)
    |> Ash.Query.load([:definition])
    |> Ash.read!()
  end

  defp reset_form do
    Timeclock.Absences.Absence
    |> AshPhoenix.Form.for_create(:create)
    |> to_form()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <div>
        <h1 class="text-3xl font-extrabold tracking-tight text-gray-900">Time-Off Requests</h1>
        <p class="text-sm text-gray-500 mt-1">Submit leave adjustments, select balance type definitions, and monitor administrative lifecycle approvals.</p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Leave Submission Panel Form -->
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit lg:col-span-1">
          <h2 class="text-lg font-bold text-gray-900 mb-4">File Time-Off Request</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Leave Classification</label>
              <.input field={@form[:definition_id]} type="select" options={@definition_options} prompt="Select absence category..." class="mt-1 block w-full rounded border-gray-300 text-sm" />
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Start Date</label>
                <.input field={@form[:start_date]} type="date" class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">End Date</label>
                <.input field={@form[:end_date]} type="date" class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold text-gray-700 uppercase tracking-wider">Justification Notes</label>
              <.input field={@form[:comment]} type="textarea" placeholder="Provide reason parameters..." rows="3" class="mt-1 block w-full rounded border-gray-300 text-sm shadow-sm" />
            </div>

            <button type="submit" class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 rounded-lg text-sm transition shadow-sm">
              Submit Leave Request
            </button>
          </.form>
        </div>

        <!-- Ledger History List Tracking View -->
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Your Absence Ledger Records</h2>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm text-left">
              <thead>
                <tr class="text-gray-500 font-medium bg-gray-50">
                  <th class="p-3">Category</th>
                  <th class="p-3">Timeframe Bounds</th>
                  <th class="p-3 text-center">Status</th>
                  <th class="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 text-gray-700">
                <tr :for={abs <- @absences} id={"absence-row-#{abs.id}"}>
                  <td class="p-3 font-semibold text-gray-900">
                    {if abs.definition, do: abs.definition.name, default: "Standard Leave"}
                    <span :if={Map.has_key?(abs, :comment) && abs.comment} class="block text-[10px] text-gray-400 font-normal italic mt-0.5">
                      "{abs.comment}"
                    </span>
                  </td>
                  <td class="p-3 font-mono text-xs text-gray-500">
                    {abs.start_date} → {abs.end_date}
                  </td>
                  <td class="p-3 text-center">
                    <span class={"inline-flex items-center px-2 py-0.5 rounded text-xs font-mono font-bold uppercase tracking-wider #{case Map.get(abs, :status, "pending") do "approved" -> "bg-green-100 text-green-800"; "rejected" -> "bg-red-100 text-red-800"; _ -> "bg-amber-100 text-amber-800" end}"}>
                      {Map.get(abs, :status, "pending")}
                    </span>
                  </td>
                  <td class="p-3 text-right">
                    <button 
                      :if={Map.get(abs, :status, "pending") == "pending"} 
                      type="button" 
                      phx-click="cancel_request" 
                      phx-value-id={abs.id} 
                      data-confirm="Withdraw this time-off request?" 
                      class="text-red-600 hover:underline font-semibold text-xs"
                    >
                      Cancel
                    </button>
                  </td>
                </tr>
                <tr :if={Enum.empty?(@absences)}>
                  <td colspan="4" class="p-8 text-center text-gray-400">No time-off logs registered in your personal file tracker yet.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
