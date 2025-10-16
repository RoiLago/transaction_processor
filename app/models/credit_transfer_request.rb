# app/models/bulk_transfer_request.rb
class BulkTransferRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :organization_bic, :string
  attribute :organization_iban, :string
  attribute :credit_transfers, default: []

  validates :organization_bic, :organization_iban, presence: true
  validate :validate_credit_transfers

  def initialize(attributes = {})
    super(attributes)
    # convert array of hashes into TransferRequest objects
    self.credit_transfers = (attributes[:credit_transfers] || []).map do |t|
      TransferRequest.new(t)
    end
  end

  private

  def validate_credit_transfers
    if credit_transfers.empty?
      errors.add(:credit_transfers, "cannot be empty")
    end

    credit_transfers.each do |t|
      errors.add(:credit_transfers, "invalid transfer") unless t.valid?
    end
  end
end

# app/models/transfer_request.rb
class TransferRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :amount, :decimal
  attribute :currency, :string
  attribute :counterparty_name, :string
  attribute :counterparty_bic, :string
  attribute :counterparty_iban, :string
  attribute :description, :string

  validates :amount, :currency, :counterparty_name, :counterparty_bic,
            :counterparty_iban, :description, presence: true
end
