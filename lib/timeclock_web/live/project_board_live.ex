defmodule TimeclockWeb.ProjectBoardLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    projects = Ash.read!(Timeclock.Projects.Project)
    tasks = fetch_tasks()
    assignments = Ash.read!(Timeclock.Projects.Assignment)

    project_options = Enum.map(projects, &{&1.name, &1.id})
    assignment_options = Enum.map(assignments, &{"Assignment: #{String.slice(&1.id, 0, 8)}", &1.id})

    form = Timeclock.Projects.Task |> AshPhoenix.Form.for_create(:create) |> to_form()
    {:ok, assign(socket, projects: projects, tasks: tasks, project_options: project_options, assignment_options: assignment_options, form: form)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params) |> to_form())}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Task allocated.") |> assign(tasks: fetch_tasks(), form: reset_form())}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  defp fetch_tasks, do: Timeclock.Projects.Task |> Ash.Query.load([:project, :assignment]) |> Ash.read!()
  defp reset_form, do: Timeclock.Projects.Task |> AshPhoenix.Form.for_create(:create) |> to_form()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-7xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Project Operations & Milestones</h1>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-fit">
          <h2 class="text-lg font-bold text-gray-900 mb-4">Provision Task</h2>
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
            <div><.input field={@form[:name]} type="text" placeholder="Task Designation Name" class="w-full text-sm" /></div>
            <div><.input field={@form[:project_id]} type="select" options={@project_options} prompt="Select parent project..." class="w-full text-sm" /></div>
            <div><.input field={@form[:assignment_id]} type="select" options={@assignment_options} prompt="Select workflow timeline route..." class="w-full text-sm" /></div>
            <div><.input field={@form[:due_date]} type="datetime-local" class="w-full text-sm" /></div>
            <div><.input field={@form[:description]} type="textarea" placeholder="Detail operational description hooks..." rows="3" class="w-full text-sm" /></div>
            <button type="submit" class="w-full bg-indigo-600 text-white font-bold py-2 rounded text-sm">Launch Task Node</button>
          </.form>
        </div>
        <div class="lg:col-span-2 bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h2 class="text-lg font-semibold text-gray-800 mb-4">Milestone Operational Board</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div :for={t <- @tasks} class="p-4 border rounded-xl bg-gray-50/50 flex flex-col justify-between" id={"task-card-#{t.id}"}>
              <div>
                <div class="flex items-start justify-between border-b pb-1.5"><span class="font-bold text-gray-900 text-sm">{t.name}</span><span class="text-xxs font-mono bg-white border px-1.5 py-0.5 rounded truncate max-w-[120px]">📂 {if t.project, do: t.project.name, default: "Global"}</span></div>
                <p class="text-xs text-gray-600 italic mt-2">"{t.description}"</p>
              </div>
              <div class="mt-4 pt-2 border-t text-[10px] text-gray-400 font-mono flex justify-between"><span>📅 Due: {t.due_date}</span></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
