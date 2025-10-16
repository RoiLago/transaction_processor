require "rails_helper"

RSpec.describe CreditTransferRequest do
  let(:valid_attributes) do
    {
      "amount" => "14.5",
      "currency" => "EUR",
      "counterparty_name" => "Counterparty",
      "counterparty_bic" => "CounterBIC",
      "counterparty_iban" => "CounterIBAN",
      "description" => "Description"
    }
  end

  describe "validations" do
    it "is valid" do
      transfer = described_class.new(valid_attributes)
      expect(transfer).to be_valid
      expect(transfer.amount_cents).to eq(1450)
    end

    it "is invalid without amount" do
      transfer = described_class.new(valid_attributes.except("amount"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:amount].size).to eq(1)
      expect(transfer.errors[:amount]).to include("can't be blank")
    end

    it "is invalid if amount is negative or zero" do
      transfer = described_class.new(valid_attributes.merge("amount" => "0"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:amount].size).to eq(1)
      expect(transfer.errors[:amount]).to include("must be greater than zero")
    end

    it "is invalid if amount cannot be parsed" do
      transfer = described_class.new(valid_attributes.merge("amount" => "abc"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:amount].size).to eq(1)
      expect(transfer.errors[:amount]).to include("must be greater than zero")
    end

    it "is invalid without currency" do
      transfer = described_class.new(valid_attributes.except("currency"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:currency].size).to eq(1)
      expect(transfer.errors[:currency]).to include("can't be blank")
    end

    it "is invalid without counterparty_name" do
      transfer = described_class.new(valid_attributes.except("counterparty_name"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:counterparty_name].size).to eq(1)
      expect(transfer.errors[:counterparty_name]).to include("can't be blank")
    end

    it "is invalid without counterparty_bic" do
      transfer = described_class.new(valid_attributes.except("counterparty_bic"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:counterparty_bic].size).to eq(1)
      expect(transfer.errors[:counterparty_bic]).to include("can't be blank")
    end

    it "is invalid without counterparty_iban" do
      transfer = described_class.new(valid_attributes.except("counterparty_iban"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:counterparty_iban].size).to eq(1)
      expect(transfer.errors[:counterparty_iban]).to include("can't be blank")
    end

    it "is invalid without description" do
      transfer = described_class.new(valid_attributes.except("description"))
      expect(transfer).not_to be_valid
      expect(transfer.errors[:description].size).to eq(1)
      expect(transfer.errors[:description]).to include("can't be blank")
    end
  end
end
