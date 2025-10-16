class BankAccount < ApplicationRecord
  self.table_name = "bank_accounts"

  has_many :transactions, foreign_key: "bank_account_id", dependent: :restrict_with_error

  validates :organization_name, :iban, :bic, :balance_cents, presence: true
  validates :iban, uniqueness: true
  validates :balance_cents, numericality: { only_integer: true } # Balance can be negative
end
