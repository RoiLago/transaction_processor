class CreditTransferRequest
  include ActiveModel::Model

  attr_reader :amount, :currency, :counterparty_name, :counterparty_bic,
              :counterparty_iban, :description

  validates :amount, :currency, :counterparty_name, :counterparty_bic,
            :counterparty_iban, :description, presence: true
  validate :amount_must_be_positive_number
  validate :amount_must_have_two_decimals_max

  def initialize(attributes = {})
    @amount = attributes["amount"]
    @currency = attributes["currency"]
    @counterparty_name = attributes["counterparty_name"]
    @counterparty_bic = attributes["counterparty_bic"]
    @counterparty_iban = attributes["counterparty_iban"]
    @description = attributes["description"]
  end

  def amount_cents
    return nil unless parsed_amount
    (parsed_amount * 100).to_i
  end


  private

  def parsed_amount
    @_parsed_amount ||= begin
                          BigDecimal(amount)
                        rescue ArgumentError, TypeError
                          nil
                        end
  end

  def amount_must_be_positive_number
    return if amount.blank?

    if parsed_amount.nil? || parsed_amount <= 0
      errors.add(:amount, "must be greater than zero")
    end
  end


  def amount_must_have_two_decimals_max
    return if parsed_amount.nil?

    scaled = parsed_amount * 100
    unless scaled.frac.zero?
      errors.add(:amount, "cannot have more than 2 decimal places")
    end
  end
end
