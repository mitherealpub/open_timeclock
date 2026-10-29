# OpenTimeclock

An enterprise-grade, multi-tenant workforce operational time-tracking, roster scheduling, and leave management system built on **Elixir**, **Phoenix LiveView 1.0+ (HEEx 2.0)**, and the **Ash 3.0 Framework**.

The architecture features at-rest cryptographic data wrappers, asynchronous event notifier pipelines backed by transactional outboxes, and role-based policy access gates enforced directly at the core data layer.

## 🏛️ Domain Architecture & Resource Index

The workspace platform is cleanly divided into specialized domain context nodes under the **Ash 3.0 Engine**:

*   **`Timeclock.Accounts`**: Manages user directory access vectors, cryptographic session keys, tokens, and authorization profile parameters (`User`, `Account`, `Role`, `Employee`, `Manager`).
*   **`Timeclock.Absences`**: Orchestrates employee time-off lifecycles, leaf classification rules, and approval tracking states (`Absence`, `Definition`).
*   **`Timeclock.Clocking`**: Real-time high-fidelity attendance punch logs, terminal hardware properties, and custom kiosk interface elements (`Clocking`, `Definition`, `InterfaceDetail`).
*   **`Timeclock.Scheduling`**: Rotational shift threshold matrix parameters and employee calendar roster planners (`Schedule`, `Shift`, `BreakRule`).
*   **`Timeclock.Projects`**: Links workforce allocations down to specific project milestones and deadlines (`Project`, `Assignment`, `Task`).
*   **`Timeclock.System`**: Manages system constants, localized codes, tax values, and database options (`Settings`, `Status`, `Tag`, `Code`).

---

## 🖥️ Active Operational LiveView Manifest

All interfaces leverage modern **HEEx 2.0 `{ expression }` brace syntax**, localized format rendering adapters, and Phoenix LiveView stream synchronization loops:

### ⏱️ User & Kiosk Workspaces (`/home`)
*   **Dashboard Gateway (`/home`)**: An analytics landing board computing overall identity registry indexes, active trackers, and navigation cards.
*   **Kiosk Punch Terminal (`/home/terminal`)**: A lightweight real-time workplace attendance ledger with embedded subform toggle matrices tracking GPS `Geolocation` parameters.
*   **Leave Requests (`/home/time-off`)**: Personal leave submission portal enabling workers to file leaf files, check balances, and monitor execution lines.

### 🏢 Administrative Strategy Suites (`/admin`)
*   **Live Presence Tracker (`/admin/online/:name`)**: A streaming directory hooked to `Phoenix.PubSub` displaying active browser devices.
*   **Corporate Layout Panel (`/admin/infrastructure`)**: Structural management map allowing creation of legal organizations, companies, and nested `Address` records.
*   **Roster Shift Planner (`/admin/roster-planner`)**: Calendar coordinator for binding structured rotational spans directly onto employee rosters.
*   **Timeline Gantt Planner (`/admin/schedule-gantt`)**: A visual schedule manager using raw CSS Grid layouts and inline parameters modification sidebars.
*   **Milestone Operations Board (`/admin/operations-board`)**: Milestone delegation deck pairing task tracks to projects and tracking constraints.
*   **Operations Approvals (`/admin/approvals`)**: Dynamic cockpit for managers to sign off on leave items or reject overrides with integrated background notification loops.
*   **System settings (`/admin/system-settings`)**: Administrator dashboard handling encrypted global constants, SMTP pools, and SES tokens securely via Cloak adapters.

---

## 🛠️ Security & Authorization Policies

Access criteria are strictly locked down directly within your Ash Resource definition layers using role assertions:

1.  **Submission Access**: Any verified connection context can create/read their own data parameters (e.g., punching in or filing a leave request).
2.  **Signature Access**: Only user accounts explicitly attached to an authoritative `Role` relation (such as `"admin"` or `"manager"`) can invoke state transition methods like `approve_absence` or `approve_workflow`.
3.  **Routing Access**: The `/admin/*` router branches are filtered prior to mounting via the `LiveUserAuth` mount hook pipeline, bouncing invalid accounts securely back to home.

---

## 📦 System Dependencies Core

Important foundational engines included in your `mix.exs` framework manifest:

*   **`ash` & `ash_postgres`**: Core data-layer definition frameworks modeling resources to PostgreSQL constraints cleanly.
*   **`oban` & `ash_oban`**: Transactional outbox managers moving slow operations (like email generation) into async background queues.
*   **`cloak_ecto`**: Transparent database field encryption wrapper protecting secure data blocks (such as mailer API keys) at rest via `Timeclock.Vault`.
*   **`ex_cldr`**: Multi-locale formatting utility processing localized floating metrics and strings translation sets cleanly.

---

## 🚀 Local Development Environment Setup

### Prerequisites
Ensure your local container environment has **Elixir 1.15+**, **Erlang/OTP 26+**, and a running **PostgreSQL** database node instance active.

### 1. Bootstrap the System Matrix
Run the comprehensive automation configuration pipeline to pull down your dependency packages tree, build compilation binaries, generate schema migrations, and inject baseline seeds records (`priv/repo/seeds.exs`):
```bash
mix setup
```

### 2. Generate Ecto Migrations Manually (Optional)
If you modify resource tracking parameters, invoke the Ash Postgres builder to output localized schema changes files cleanly:
```bash
mix ash_postgres.generate_migrations
```

### 3. Boot Up the Application Server
Fire up your native Phoenix routing core server nodes locally:
```bash
mix phx.server
```
Once booted, visit `http://localhost:4000/home` inside your browser to open up the platform landing dashboard workspace.

### 🧪 4. Execute Automated Assertion Suites
Trigger your local testing pipelines to verify structural changes regressions and policy check validations pass cleanly:
```bash
mix test
```
