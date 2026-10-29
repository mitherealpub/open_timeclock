defmodule Timeclock.Approvals.Approval do
  use Ash.Resource,
    otp_app: :timeclock,
    domain: Timeclock.Approvals,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]
    extensions: []

  attributes do
    uuid_primary_key :id

    # Period info
    attribute :period_start, :utc_datetime do
      public? true
      allow_nil? false
    end

    attribute :period_end, :utc_datetime do
      public? true
      allow_nil? false
    end

    attribute :period_options, :map do
      public? true
      allow_nil? false
    end

    # Status info
    attribute :status, :string do
      public? true
      allow_nil? false
    end

    attribute :is_dirty, :boolean do
      public? true
      default false
    end

    # Additional data
    attribute :additional_data, Timeclock.Approvals.AdditionalData do
      public? true
      allow_nil? false
    end

    attribute :icon, Timeclock.Types.Icon do
      public? true
      allow_nil? false
    end

    # Partial time
    attribute :is_partial, :boolean do
      public? true
      default false
    end

    attribute :partial_time_from, :time do
      public? true
    end

    attribute :partial_time_to, :time do
      public? true
    end

    # Current approvers
    attribute :current_approver_names, :map do
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_id, [:id]
  end

  postgres do
    table "approval_requests"
    repo Timeclock.Repo
  end

  relationships do
    belongs_to :status_set_by_user, Timeclock.Accounts.User do
      public? true
    end

    belongs_to :user, Timeclock.Accounts.User do
      public? true
    end

    belongs_to :request_definition, Timeclock.Approvals.Definition do
      public? true
    end
  end

  validations do
    validate present([:user_id, :period_start]), on: [:create, :update]
    validate one_of(:is_partial, [true, false]), on: [:create, :update]
  end

  actions do
    defaults [:read, :destroy, create: :*]
  end

  preparations do
    prepare build(
              load: [
                :user,
                :status_set_by_user,
                :icon,
                :definition
              ]
            )
  end

  # Inside your defmodule Timeclock.Approvals.Approval block:
policies do
  # Rule 1: Submission access is global
  policy action_type(:create) do
    authorize_if always()
  end

  # Rule 2: Signature write access is restricted to authoritative actors
  policy action(:update) do
    authorize_if RelatesToActorVia([:user, :role, name: :admin])
    authorize_if RelatesToActorVia([:user, :role, name: :manager])
  end
end

end
