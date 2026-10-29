defmodule TimeclockWeb.OrganizationDashboardLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    orgs = Ash.read!(Timeclock.Organizations.Organization)
    comps = fetch_companies()
    depts = Ash.read!(Timeclock.Organizations.Department)

    org_options = Enum.map(orgs, &{&1.name, &1.id})
    comp_options = Enum.map(comps, &{&1.name, &1.id})

    comp_form = Timeclock.Organizations.Company |> AshPhoenix.Form.for_create(:create, params: %{"address" => %{}}) |> to_form()
    dept_form = Timeclock.Organizations.Department |> AshPhoenix.Form.for_create(:create) |> to_form()

    {:ok, assign(socket, orgs: orgs, comps: comps, depts: depts, org_options: org_options, comp_options: comp_options, comp_form: comp_form, dept_form: dept_form)}
  end

  @impl true
  def handle_event("validate_comp", %{"form" => params}, socket) do
    {:noreply, assign(socket, comp_form: AshPhoenix.Form.validate(socket.assigns.comp_form, params) |> to_form())}
  end

  @impl true
  def handle_event("save_comp", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.comp_form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Entity generated.") |> assign(comps: fetch_companies(), comp_form: reset_comp_form())}
      {:error, form} -> {:noreply, assign(socket, comp_form: to_form(form))}
    end
  end

  @impl true
  def handle_event("validate_dept", %{"form" => params}, socket) do
    {:noreply, assign(socket, dept_form: AshPhoenix.Form.validate(socket.assigns.dept_form, params) |> to_form())}
  end

  @impl true
  def handle_event("save_dept", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.dept_form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Department allocated.") |> assign(depts: Ash.read!(Timeclock.Organizations.Department), dept_form: reset_dept_form())}
      {:error, form} -> {:noreply, assign(socket, dept_form: to_form(form))}
    end
  end

  defp fetch_companies, do: Timeclock.Organizations.Company |> Ash.Query.load([:organization]) |> Ash.read!()
  defp reset_comp_form, do: Timeclock.Organizations.Company |> AshPhoenix.Form.for_create(:create, params: %{"address" => %{}}) |> to_form()
  defp reset_dept_form, do: Timeclock.Organizations.Department |> AshPhoenix.Form.for_create(:create) |> to_form()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Infrastructure Core Configuration</h1>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="space-y-6">
          <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-4">
            <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider">Legal Entity</h2>
            <.form for={@comp_form} phx-change="validate_comp" phx-submit="save_comp" class="space-y-3">
              <div><.input field={@comp_form[:name]} type="text" placeholder="Acme Logistics" class="w-full text-xs" /></div>
              <div><.input field={@comp_form[:organization_id]} type="select" options={@org_options} prompt="Parent Core Node" class="w-full text-xs" /></div>
              <div><.input field={@comp_form[:registration_number]} type="text" placeholder="REG-ID" class="w-full text-xs" /></div>
              <div class="border p-3 rounded-lg bg-gray-50 space-y-2">
                <span class="text-[10px] font-bold text-gray-500 uppercase">Headquarters</span>
                <.inputs_for :let={addr} field={@comp_form[:address]}>
                  <div><.input field={addr[:street]} type="text" placeholder="Street Address" class="w-full text-xxs" /></div>
                  <div class="grid grid-cols-2 gap-2">
                    <div><.input field={addr[:city]} type="text" placeholder="City" class="w-full text-xxs" /></div>
                    <div><.input field={addr[:state]} type="text" placeholder="State" class="w-full text-xxs" /></div>
                  </div>
                  <div class="grid grid-cols-2 gap-2">
                    <div><.input field={addr[:postal_code]} type="text" placeholder="ZIP" class="w-full text-xxs" /></div>
                    <div><.input field={addr[:country]} type="text" placeholder="Country" class="w-full text-xxs" /></div>
                  </div>
                </.inputs_for>
              </div>
              <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-xs">Provision Company</button>
            </.form>
          </div>
          <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-4">
            <h2 class="text-sm font-bold text-gray-700 uppercase tracking-wider">Department</h2>
            <.form for={@dept_form} phx-change="validate_dept" phx-submit="save_dept" class="space-y-3">
              <div><.input field={@dept_form[:name]} type="text" placeholder="Quality Assurance" class="w-full text-xs" /></div>
              <div><.input field={@dept_form[:company_id]} type="select" options={@comp_options} prompt="Business Unit" class="w-full text-xs" /></div>
              <button type="submit" class="w-full bg-blue-600 text-white font-bold py-2 rounded text-xs">Create Unit Node</button>
            </.form>
          </div>
        </div>
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-bold text-gray-900 mb-4">Operations Map Directory</h2>
          <div class="space-y-4">
            <div :for={c <- @comps} class="p-4 border rounded-xl bg-gray-50/50 space-y-2" id={"company-card-#{c.id}"}>
              <div class="flex justify-between items-center font-bold">
                <div>
                  <span class="text-gray-900">{c.name}</span>
                  <span class="block text-xxs text-gray-400">Code: {c.registration_number}</span>
                </div>
                <span class="text-xxs px-2 py-0.5 rounded bg-indigo-100 text-indigo-800">{if c.organization, do: c.organization.name, default: "Root"}</span>
              </div>
              <div :if={c.address} class="text-xxs text-gray-500 font-mono bg-white p-2 rounded border border-gray-100 shadow-inner">
                {c.address.street}, {c.address.city}, {c.address.state} {c.address.postal_code}, {c.address.country}
              </div>
              <div class="flex flex-wrap gap-1.5 pt-1">
                <span :for={d <- @depts} :if={d.company_id == c.id} class="px-2 py-0.5 text-xxs rounded bg-blue-50 text-blue-700 border border-blue-200">{d.name}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
