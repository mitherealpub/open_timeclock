defmodule TimeclockWeb.SystemSettingsLive do
  use TimeclockWeb, :live_view
  import AshPhoenix.Form

  @impl true
  def mount(_params, _session, socket) do
    settings = case Ash.read!(Timeclock.System.Settings) do
      [] -> Ash.create!(Timeclock.System.Settings, :init)
      [record | _] -> record
    end

    form = settings |> AshPhoenix.Form.for_update(:update) |> to_form()
    
    provider_options = [{"SMTP Server Delivery", "smtp"}, {"SendGrid API", "sendgrid"}, {"Mailgun Engine", "mailgun"}, {"Postmark Client", "postmark"}, {"Brevo Suite", "brevo"}, {"Amazon SES", "amazon_ses"}]
    tls_options = [{"Upgrade if Available", "if_available"}, {"Enforce TLS Encryption", "always"}, {"Plain Communication", "never"}]

    {:ok, assign(socket, settings: settings, form: form, provider_options: provider_options, tls_options: tls_options)}
  end

  @impl true
  def handle_event("validate", %{"form" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params) |> to_form())}
  end

  @impl true
  def handle_event("save", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, fresh} -> {:noreply, socket |> put_flash(:info, "System properties optimized.") |> assign(settings: fresh, form: AshPhoenix.Form.for_update(fresh, :update) |> to_form())}
      {:error, form} -> {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 max-w-4xl mx-auto space-y-6">
      <h1 class="text-2xl font-bold text-gray-900">Global Communication Parameters</h1>
      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><.input field={@form[:email_from_name]} type="text" placeholder="Sender Name" class="w-full text-sm" /></div>
            <div><.input field={@form[:email_from_address]} type="email" placeholder="noreply@site.com" class="w-full text-sm" /></div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 border-t pt-4">
            <div><.input field={@form[:email_provider]} type="select" options={@provider_options} class="w-full text-sm" /></div>
            <div><.input field={@form[:email_api_domain]} type="text" placeholder="://site.com" class="w-full text-sm" /></div>
            <div><.input field={@form[:email_api_region]} type="text" placeholder="us-east-1" class="w-full text-sm" /></div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><.input field={@form[:email_api_key]} type="password" placeholder="API Key Mask" class="w-full text-sm" /></div>
            <div><.input field={@form[:email_api_secret]} type="password" placeholder="API Secret Mask" class="w-full text-sm" /></div>
          </div>
          <div :if={Phoenix.HTML.Form.input_value(@form, :email_provider) == :smtp || Phoenix.HTML.Form.input_value(@form, :email_provider) == "smtp"} class="space-y-4 pt-4 border-t bg-gray-50 p-4 rounded-xl">
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div class="sm:col-span-2"><.input field={@form[:smtp_host]} type="text" placeholder="smtp.relay.io" class="w-full text-sm bg-white" /></div>
              <div><.input field={@form[:smtp_port]} type="number" class="w-full text-sm bg-white" /></div>
              <div><.input field={@form[:smtp_username]} type="text" class="w-full text-sm bg-white" /></div>
              <div><.input field={@form[:smtp_password]} type="password" placeholder="Password Code" class="w-full text-sm bg-white" /></div>
              <div><.input field={@form[:smtp_tls]} type="select" options={@tls_options} class="w-full text-sm bg-white" /></div>
            </div>
          </div>
          <div class="flex justify-end pt-2 border-t"><button type="submit" class="bg-indigo-600 text-white font-semibold py-2 px-6 rounded shadow hover:bg-indigo-700 transition text-sm">Overwrite System Metrics</button></div>
        </.form>
      </div>
    </div>
    """
  end
end
