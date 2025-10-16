class TransferService
  attr_reader :errors

  BATCH_SIZE = 1000

  def initialize(bulk_request)
    @bulk_request = bulk_request
    @errors = []
  end

  def process
    transfers_data = []
    total_cents = 0

    @bulk_request.credit_transfers.each_with_index do |t, i|
      begin
        amount_cents = (BigDecimal(t[:amount]) * 100).to_i
      rescue ArgumentError
        @errors << "Invalid amount for transfer #{i + 1}"
        return false
      end

      if amount_cents <= 0
        @errors << "Transfer #{i + 1} amount must be positive"
        return false
      end

      total_cents += amount_cents

      transfers_data << {
        counterparty_name: t[:counterparty_name],
        counterparty_iban: t[:counterparty_iban],
        counterparty_bic: t[:counterparty_bic],
        description: t[:description],
        amount_cents: amount_cents,
        # created_at: Time.current,
        # updated_at: Time.current
      }
    end

    bank_account = BankAccount.find_by(
      iban: @bulk_request.organization_iban,
      bic: @bulk_request.organization_bic
    )

    unless bank_account
      @errors << "Bank account not found"
      return false
    end

    updated_rows = BankAccount
                     .where(id: bank_account.id)
                     .where("balance_cents >= ?", total_cents)
                     .update_all("balance_cents = balance_cents - #{total_cents}")

    if updated_rows == 0
      @errors << "Insufficient funds"
      return false
    end

    transfers_data.each_slice(BATCH_SIZE) do |batch|
      batch.each { |t| t[:bank_account_id] = bank_account.id }
      Transfer.insert_all!(batch)
    end

    true
  rescue => e
    @errors << e.message
    false
  end
end
