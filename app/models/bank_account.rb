class BankAccount < ApplicationRecord
  self.table_name = "bank_accounts"

  has_many :transfers, foreign_key: "bank_account_id"

  validates :iban, :bic, presence: true
end
