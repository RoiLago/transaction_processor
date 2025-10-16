class Transaction < ApplicationRecord
  self.table_name = "transactions"

  belongs_to :bank_account, foreign_key: "bank_account_id"

  validates :counterparty_name, :counterparty_iban, :amount_cents, :amount_currency, :bank_account_id, :description, presence: true
  validates :amount_cents, numericality: { only_integer: true }
end
