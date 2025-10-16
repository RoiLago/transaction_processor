class Transaction < ApplicationRecord
  self.table_name = "transactions"

  belongs_to :bank_account, foreign_key: "bank_account_id"

  # todo validates all fields present
  validates :amount_cents, :counterparty_iban, :counterparty_name, presence: true
end
