defmodule Timeclock.Absences.Absence do
  use Ash.Resource,
    otp_app: :timeclock,
    domain: Timeclock.Absences,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]
    extensions: []

  attributes do
    uuid_primary_key :id

    attribute :start_date, :utc_datetime do
      public? true
      allow_nil? false
    end

    attribute :end_date, :utc_datetime do
      public? true
      allow_nil? false
    end

    attribute :reason, :string do
      public? true
      allow_nil? false
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_id, [:id]
  end

  relationships do
    belongs_to :user, Timeclock.Accounts.User do
      public? true
    end

    belongs_to :status, Timeclock.System.Status do
      public? true
    end

    belongs_to :approved_by, Timeclock.Accounts.User do
      public? true
    end

    belongs_to :absence_definition, Timeclock.Absences.Definition do
      public? true
    end
  end

  postgres do
    table "absences"
    repo Timeclock.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*]
  end

  preparations do
    prepare build(load: [:status, :user, :approved_by, :absence_definition])
  end

  # Inside your defmodule Timeclock.Absences.Absence block:
policies do
  # Rule 1: Anyone can view their own requests, and create new ones
  policy action_type([:read, :create]) do
    authorize_if always()
  end

  # Rule 2: Restrict update actions (like status modifications) to specific roles
  policy action_type(:update) do
    # Assuming your user resource has a relationship or attribute mapping to roles:
    authorize_if RelatesToActorVia([:user, :role, name: :admin])
    authorize_if RelatesToActorVia([:user, :role, name: :manager])
    
    # Otherwise, if roles are an embedded list or attribute array on the user:
    # authorize_if actor_attribute_equals(:role, :admin)
  end
end

end
