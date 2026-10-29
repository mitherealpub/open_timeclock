defmodule Timeclock.Accounts do
  use Ash.Domain, otp_app: :timeclock, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Timeclock.Accounts.Token

    resource Timeclock.Accounts.User do
      define :get_user_by_email, args: [:email], action: :get_by_email
      define :list_users, action: :list
    end

    resource Timeclock.Accounts.Account do
      define_calculation :full_name, args: [:_record]
    end

    resource Timeclock.Accounts.Employee
    resource Timeclock.Accounts.Manager
    resource Timeclock.Accounts.Role
    resource Timeclock.Accounts.UserRole 
  end
end
