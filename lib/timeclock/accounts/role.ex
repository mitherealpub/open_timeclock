defmodule Timeclock.Accounts.Role do
  use Ash.Resource,
    otp_app: :timeclock,
    domain: Timeclock.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [],
    extensions: []

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
    end

    attribute :permissions, {:array, :string} do
      public? true
      allow_nil? false
      default []
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
  end

  postgres do
    table "roles"
    repo Timeclock.Repo
  end

  relationships do
    belongs_to :user, Timeclock.Accounts.User do
      public? true
    end
  end

  actions do
    defaults [:destroy, create: :*]

    # Explicitly overridden read action providing clean, isolated relationship loading filters
    read :read do
      primary? true
      prepare build(load: [:user])
    end
  end
end
