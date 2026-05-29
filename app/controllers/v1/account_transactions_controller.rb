module V1
  class AccountTransactionsController < ApiController
    before_action -> { authenticate_token!("TRANSACTIONS_READ") }

    def index
      account = Account.find_by!(external_id: params[:account_id])
      Security::Authorizer.require_consent_customer!(account, current_consent)

      transactions = account.ledger_transactions.order(posted_at: :desc).limit(100)
      render json: { transactions: transactions.map { |transaction| ApiSerializer.transaction(transaction) } }
    end
  end
end
