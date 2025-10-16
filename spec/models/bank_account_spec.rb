require "rails_helper"

RSpec.describe BankAccount, type: :model do
  subject do
    described_class.new(
      organization_name: "Test Org",
      iban: "IBAN123",
      bic: "BIC123",
      balance_cents: 10_000
    )
  end

  describe "validations" do
    it "is valid with all attributes" do
      expect(subject).to be_valid
    end

    it "is invalid without organization_name" do
      subject.organization_name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:organization_name]).to include("can't be blank")
    end

    it "is invalid without iban" do
      subject.iban = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:iban]).to include("can't be blank")
    end

    it "is invalid without bic" do
      subject.bic = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:bic]).to include("can't be blank")
    end

    it "requires iban to be unique" do
      described_class.create!(
        organization_name: "Other Org",
        iban: "IBAN123",
        bic: "BIC999",
        balance_cents: 1000
      )
      expect(subject).not_to be_valid
      expect(subject.errors[:iban]).to include("has already been taken")
    end

    it "allows negative balance" do
      subject.balance_cents = -500
      expect(subject).to be_valid
    end

    it "requires balance_cents to be an integer" do
      subject.balance_cents = 10.5
      expect(subject).not_to be_valid
      expect(subject.errors[:balance_cents]).to include("must be an integer")
    end
  end

  describe "associations" do
    it "has many transactions" do
      assoc = described_class.reflect_on_association(:transactions)
      expect(assoc.macro).to eq(:has_many)
    end
  end

  describe "deletion" do
    let!(:account) { BankAccount.create!(organization_name: "Test Org", iban: "IBAN1", bic: "BIC1", balance_cents: 1000) }

    it "prevents deletion if there are transactions" do
      account.transactions.create!(
        counterparty_name: "Alice",
        counterparty_iban: "IBAN2",
        counterparty_bic: "BIC2",
        description: "Payment",
        amount_cents: 100,
        amount_currency: "EUR"
      )

      expect(account.destroy).to eq(false)
      expect(BankAccount.exists?(account.id)).to be(true)
    end

    it "allows deletion if no transactions exist" do
      expect(account.destroy).to be_truthy
    end
  end
end
