class BulkTransferRequest
  include ActiveModel::Model

  validates :organization_bic, :organization_iban, :credit_transfers, presence: true
  validate :validate_credit_transfers

  attr_reader :organization_bic, :organization_iban, :credit_transfers

  def self.from_json(raw_json)
    begin
      json_hash = JSON.parse(raw_json)
      new(json_hash)
    rescue JSON::ParserError => e
      obj = new
      obj.errors.add(:base, "Invalid JSON: #{e.message}")
      obj
    end
  end

  def total_cents
    @_total_cents ||= credit_transfers.sum(&:amount_cents)
  end

  private

  def initialize(attributes = {})
    @organization_bic = attributes["organization_bic"]
    @organization_iban = attributes["organization_iban"]

    raw_transfers = attributes["credit_transfers"] || []
    @credit_transfers = (raw_transfers).map do |t|
      CreditTransferRequest.new(t)
    end
  end

  def validate_credit_transfers
    if credit_transfers.empty?
      errors.add(:credit_transfers, "cannot be empty")
    end

    credit_transfers.each do |t|
      next if t.valid?

      t.errors.full_messages.each do |msg|
        desc = t.description || "(no description)"
        errors.add(:credit_transfers, "Invalid transaction with description => #{desc}: #{msg}")
      end
    end
  end
end
