require "rails_helper"

RSpec.describe Transaction, type: :model do
  let!(:bank_account) { BankAccount.create!(organization_name: "Test Org", iban: "IBAN1", bic: "BIC1", balance_cents: 10_000) }

  subject(:transaction) do
    described_class.new(
      counterparty_name: "Alice",
      counterparty_iban: "IBAN2",
      counterparty_bic: "BIC2",
      amount_cents: 1_000,
      amount_currency: "EUR",
      description: "Payment",
      bank_account: bank_account
    )
  end

  describe "associations" do
    it "belongs to a bank account" do
      expect(transaction.bank_account).to eq(bank_account)
    end
  end

  describe "validations" do
    it "is valid with all required attributes" do
      expect(transaction).to be_valid
    end

    it "is invalid without counterparty_name" do
      transaction.counterparty_name = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:counterparty_name]).to include("can't be blank")
    end

    it "is invalid without counterparty_iban" do
      transaction.counterparty_iban = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:counterparty_iban]).to include("can't be blank")
    end

    it "is invalid without amount_cents" do
      transaction.amount_cents = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount_cents]).to include("can't be blank")
    end

    it "is invalid without amount_currency" do
      transaction.amount_currency = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount_currency]).to include("can't be blank")
    end

    it "is invalid without bank_account_id" do
      transaction.bank_account = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:bank_account]).to include("must exist")
    end

    it "is invalid without description" do
      transaction.description = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:description]).to include("can't be blank")
    end
  end
end
