defmodule Timeclock.Accounts.UserRole do
  use Ash.Resource,
    otp_app: :timeclock,
    domain: Timeclock.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "user_roles"
    repo Timeclock.Repo
  end

  relationships do
    belongs_to :user, Timeclock.Accounts.User do
      primary_key? true
      allow_nil? false
      public? true
    end

    belongs_to :role, Timeclock.Accounts.Role do
      primary_key? true
      allow_nil? false
      public? true
    end
  end

  actions do
    defaults [:read, :destroy, create: :*]
  end
end
