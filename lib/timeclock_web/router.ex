defmodule TimeclockWeb.Router do
  use TimeclockWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  alias TimeclockWeb.LiveUserAuth
  alias TimeclockWeb.AuthOverrides
  alias AshAuthentication.Phoenix.Overrides.Default

  @csp Enum.join(
         [
           "default-src 'self'",
           "base-uri 'self'",
           "frame-ancestors 'self'",
           "img-src 'self' data: blob:",
           "style-src 'self' 'unsafe-inline'",
           "font-src 'self' data:",
           "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
           "connect-src 'self' ws: wss:"
         ],
         "; "
       )

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimeclockWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_csp
    plug :load_from_session
    plug :put_session_timezone
  end

  pipeline :user do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimeclockWeb.Layouts, :user}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_csp
    plug :load_from_session
    plug :put_session_timezone
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  # Unauthenticated Strategy Authentication Paths
  scope "/", TimeclockWeb do
    pipe_through :browser

    get "/", PageController, :landing
    auth_routes AuthController, Timeclock.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Standard Email Registration and Login Screens
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{LiveUserAuth, :live_no_user}],
                  overrides: [
                    AuthOverrides,
                    Default,
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                  ]

    # Password Reset Actions Gateway
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  AuthOverrides,
                  Default,
                  Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                ]

    # New Identity Email Confirmation Strategy Route
    confirm_route Timeclock.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [TimeclockWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]

    # Tokenless Magic-Link Strategy Verification Route
    magic_sign_in_route(Timeclock.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]
    )
  end

  # User Home & General Workspace Paths
  scope "/home" do
    pipe_through [:browser, :user]

    ash_authentication_live_session :authenticated_user,
      on_mount: [
        {LiveUserAuth, :live_user_required}, 
        {AshScope, :current_scope},
        {LiveUserAuth, :user_setup}
      ] do
      live "/", TimeclockWeb.Dashboard.IndexLive, :index
      live "/setup", TimeclockWeb.System.SetupLive, :index
      
      # Real-Time Employee Clocking Punch Kiosk Terminal View
      live "/terminal", TimeclockWeb.ClockingTerminalLive, :index
    end
  end

  # Administrative Panels & Operational Control Domains
  scope "/admin", TimeclockWeb do
    pipe_through [:browser, :user]

    ash_authentication_live_session :authentication_required,
      on_mount: [
        {LiveUserAuth, :live_user_required}, 
        {AshScope, :current_scope},
        {LiveUserAuth, :user_setup}
      ] do
      # Phoenix Presence Live Monitoring Dashboard
      live "/online/:name", OnlineLive, :index

      # Corporate Topologies & Geographic Location Managers
      live "/infrastructure", OrganizationDashboardLive, :index

      # Employee Rotational Shifts & Roster Scheduler 
      live "/roster-planner", ScheduleRosterLive, :index

      # Gantt-Timeline UI Interactive Scheduler & Editor
      live "/schedule-gantt", ScheduleGanttLive, :index

      # Corporate Calendars, Milestones & Institutional Holiday Matrix
      live "/calendar-events", CalendarDashboardLive, :index

      # Project Scope Allocation & Deliverables Task Boards
      live "/operations-board", ProjectBoardLive, :index

      # Encrypted System Settings & Swoosh SMTP Configuration
      live "/system-settings", SystemSettingsLive, :index

      live "/time-off", AbsenceRequestLive, :index
    end
  end

  scope "/admin", TimeclockWeb do
  pipe_through [:browser, :user]

  ash_authentication_live_session :authentication_required,
    on_mount: [
      {LiveUserAuth, :live_user_required}, 
      # You can add your role check macro straight into the routing stack!
      {LiveUserAuth, {:required_roles, [:admin, :manager]}},
      {AshScope, :current_scope}
    ] do
    live "/approvals", AdminApprovalsLive, :index
  end
end

  # Core API Integration Scope
  scope "/api", TimeclockWeb do
    pipe_through :api
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:timeclock, :dev_routes) do
    import Phoenix.LiveDashboard.Router
    import AshAdmin.Router

    admin_browser_pipeline(:browser)

    scope "/dev" do
      pipe_through :browser

      # Ash Engine Native Administrative UI Dashboard Panel
      ash_admin "/admin"
      
      # Native Engine Performance Telemetry Diagnostics Logs
      live_dashboard "/dashboard", metrics: TimeclockWeb.Telemetry

      # Mailer Transmissions Local Sandbox Preview Panel
      forward "/mailbox", Plug.Swoosh.MailboxPreview,
        csp_nonce_assign_key: %{script: :script_csp_nonce, style: :style_csp_nonce}
    end
  end

  # Private Pipeline Helper Plugs
  defp put_csp(conn, _opts), do: Plug.Conn.put_resp_header(conn, "content-security-policy", @csp)

  defp put_session_timezone(conn, _opts) do
    timezone = conn.cookies["timezone"]
    put_session(conn, "timezone", timezone)
  end
end
