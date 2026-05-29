module V1
  class AccountsController < ApiController
    before_action -> { authenticate_token!("ACCOUNTS_READ") }, only: %i[index show]
    before_action -> { authenticate_token!("BALANCES_READ") }, only: :balances

    def index
      accounts = current_consent.sandbox_customer.accounts.order(:created_at)
      render json: { accounts: accounts.map { |account| ApiSerializer.account(account) } }
    end

    def show
      render json: { account: ApiSerializer.account(find_account) }
    end

    def balances
      render json: { balance: ApiSerializer.balance(find_account) }
    end

    private

    def find_account
      account = Account.find_by!(external_id: params[:id])
      Security::Authorizer.require_consent_customer!(account, current_consent)
      account
    end
  end
end
