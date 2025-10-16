class TransferService
  attr_reader :bulk_request, :errors

  BATCH_SIZE = ENV["TRANSFER_BATCH_SIZE"] || 1000

  class TransferError < StandardError; end

  def initialize(bulk_request)
    @bulk_request = bulk_request
    @errors = []
  end

  def process
    ActiveRecord::Base.transaction do
      account = BankAccount
                  .lock
                  .select(:id, :balance_cents)
                  .find_by(
                    iban: bulk_request.organization_iban,
                    bic:  bulk_request.organization_bic
                  )

      raise TransferError, "Bank account not found" unless account
      raise TransferError, "Insufficient funds" if account.balance_cents < bulk_request.total_cents

      build_transaction_hashes(account).each_slice(BATCH_SIZE) do |batch|
        Transaction.insert_all!(batch)
      end

      account.update_column(:balance_cents, account.balance_cents - bulk_request.total_cents)
    end

    true
  rescue TransferError => e
    fail!(e.message)
  rescue => e
    fail!("Unexpected error: #{e.message}")
  end

  private

  def build_transaction_hashes(account)
    bulk_request.credit_transfers.map do |t|
      {
        counterparty_name: t.counterparty_name,
        counterparty_iban: t.counterparty_iban,
        counterparty_bic: t.counterparty_bic,
        amount_cents: -t.amount_cents,
        amount_currency: t.currency,
        bank_account_id: account.id,
        description: t.description
      }
    end
  end

  def fail!(message)
    errors << message
    false
  end
end
