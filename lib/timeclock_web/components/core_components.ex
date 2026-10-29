defmodule TimeclockWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS Timeclock,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational Timeclock
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: TimeclockWeb.Gettext

  import TimeclockWeb.Components.Card
  import TimeclockWeb.Components.Button
  import TimeclockWeb.Components.Breadcrumb
  import TimeclockWeb.Components.Avatar
  import TimeclockWeb.Components.Badge
  import TimeclockWeb.Components.Indicator
  import TimeclockWeb.Components.Timeline

  alias Phoenix.LiveView.JS

  attr :title, :string, required: false, default: "Web Clock"
  attr :timezone, :string, required: false, default: "en-US"
  attr :presence, :string, required: false, default: "Not Logged In"
  attr :balance, :string, required: false, default: "0"
  attr :buttons, :list, required: false, default: []
  attr :class, :string, required: false, default: ""
  attr :current_user, :map, required: true

  def web_clock(assigns) do
    ~H"""
    <.card class="rounded-lg">
      <.card_title class="mx-4 my-2">
        <div class="mx-auto flex justify-between">
          <div class="w-1/2">
            {@title}
          </div>
          <div class="w-1/2 text-right" phx-hook=".CurrentTime" id="current-time"></div>

          <script :type={Phoenix.LiveView.ColocatedHook} name=".CurrentTime">
            export default {
              mounted() {
                let formatter = new Intl.DateTimeFormat(window.navigator.language, {
                  hour: "2-digit",
                  minute: "2-digit",
                  second: "2-digit",
                  hour12: true,
                });
                let date = new Date()
                this.el.innerHTML = formatter.format(date);
                setInterval(() => {
                  let date = new Date()
                  this.el.innerHTML = formatter.format(date);
                }, 1000);
              }
            }
          </script>
        </div>
      </.card_title>
      <.card_content padding="medium" class={@class}>
        <div class="flex mx-auto px-4 justify-between mt-4">
          <div class="w-1/2 text-sm">
            Presence: {if assigns[:current_user] && @current_user.status, do: @current_user.status.name, default: "Offline"}
          </div>
          <div class="w-1/2 text-sm text-right">
            Balance: {if assigns[:current_user], do: @current_user.balance, default: "0"}
          </div>
        </div>
        <div class="flex justify-center mt-5 px-10 mx-auto gap-2 pb-8">
          <div :for={b <- @buttons}>
            <!-- Upgraded to native HEEx 2.0 conditional attribute syntax rules -->
            <.button 
              :if={assigns[:current_user] && @current_user.status && @current_user.status.name == b.name} 
              icon={"hero-#{b.icon}"} 
              color="transparent"
            >
              {b.name}
            </.button>
            <.button 
              :if={!assigns[:current_user] || !@current_user.status || @current_user.status.name != b.name} 
              icon={"hero-#{b.icon}"} 
              color="primary"
            >
              {b.name}
            </.button>
          </div>
        </div>
      </.card_content>
    </.card>
    """
  end

  attr :title, :string, required: false, default: "Presence"
  attr :class, :string, required: false, default: ""
  attr :presence_status, :list, required: false, default: []
  attr :current_user, :map, required: true

   def presence(assigns) do
    ~H"""
    <.card class="rounded-lg">
      <.card_title class="mx-4 my-2">
        {@title}
      </.card_title>
      <.card_content padding="medium" class={@class}>
        <div :for={status <- @presence_status} class="inline-block mr-2 mb-2">
          <.badge icon={status.icon} icon_class="size-4" variant="shadow" color={status.color}>
            {status.name}
          </.badge>
        </div>

        <Cinder.collection
          :if={assigns[:current_user]}
          resource={Timeclock.Accounts.User}
          actor={@current_user}
          pagination={:keyset}
        >
          <:col :let={user} field="account.picture_uri">
            <.avatar border="small" src={if user.account, do: user.account.picture_uri, default: ""}>
              <.indicator size={if user.status, do: user.status.color, default: "gray"} color="misc" bottom_left />
            </.avatar>
          </:col>
          <:col :let={user} field="status.name" filter>{if user.status, do: user.status.name, default: "Unknown"}</:col>
          <:col :let={user} field="user.message">{if Map.has_key?(user, :message), do: user.message, default: ""}</:col>
        </Cinder.collection>
      </.card_content>
    </.card>
    """
  end

  attr :title, :string, required: false, default: "Presence"
  attr :class, :string, required: false, default: ""
  attr :current_user, :map, required: true

  def user_day(assigns) do
    ~H"""
    <.card class="rounded-lg">
      <.card_title class="mx-4 my-2">
        {@title}
      </.card_title>
      <.card_content padding="medium" class={@class}>
        <.timeline points={[]} />
      </.card_content>
    </.card>
    """
  end

  attr :title, :string, required: false, default: "Presence"
  attr :class, :string, required: false, default: ""
  attr :current_user, :map, required: true

  def user_absence_requests(assigns) do
    ~H"""
    <.card class="rounded-lg">
      <.card_title class="mx-4 my-2">
        {@title}
      </.card_title>
      <.card_content padding="medium" class={@class}></.card_content>
    </.card>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(TimeclockWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(TimeclockWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  def breadcrumbs(assigns) when is_list(assigns.breadcrumbs) do
    ~H"""
    <.breadcrumb :for={b <- @breadcrumbs}>
      <:item icon={b.icon} title={b.name} link={b.link}>{b.name}</:item>
    </.breadcrumb>
    """
  end

  def breadcrumbs(assigns) when is_map(assigns.breadcrumbs) do
    ~H"""
    <.breadcrumb>
      <:item icon={@breadcrumbs.icon} title={@breadcrumbs.name} link={@breadcrumbs.link}>
        {@breadcrumbs.name}
      </:item>
    </.breadcrumb>
    """
  end

  def breadcrumbs(assigns) do
    ~H"""
    <.breadcrumb>
      <:item title={@breadcrumbs}>
        {@breadcrumbs}
      </:item>
    </.breadcrumb>
    """
  end
end
