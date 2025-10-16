require "rails_helper"

RSpec.describe BulkTransferRequest do
  let(:valid_attributes) do
    {
      "organization_bic" => "BIC",
      "organization_iban" => "IBAN",
      "credit_transfers" => [
        {
          "amount" => "14.5",
          "currency" => "EUR",
          "counterparty_name" => "Counterparty",
          "counterparty_bic" => "CounterBIC",
          "counterparty_iban" => "CounterIBAN",
          "description" => "Description"
        }
      ]
    }
  end

  describe "validations" do
    it "is valid with organization fields and valid transfers" do
      bulk_request = described_class.from_json(valid_attributes.to_json)
      expect(bulk_request).to be_valid
    end

    it "is invalid without organization_bic" do
      attrs = valid_attributes.except("organization_bic")
      bulk_request = described_class.from_json(attrs.to_json)
      expect(bulk_request).not_to be_valid
      expect(bulk_request.errors[:organization_bic]).to include("can't be blank")
    end

    it "is invalid if credit_transfers are empty" do
      attrs = valid_attributes.merge("credit_transfers" => [])
      bulk_request = described_class.from_json(attrs.to_json)
      expect(bulk_request).not_to be_valid
      expect(bulk_request.errors[:credit_transfers]).to include("cannot be empty")
    end

    it "aggregates errors from invalid transfers" do
      invalid_transfer = {
        "amount" => "0",
        "currency" => "EUR",
        "counterparty_name" => "X",
        "counterparty_bic" => "BIC",
        "counterparty_iban" => "IBAN",
        "description" => "bad"
      }

      attrs = valid_attributes.merge("credit_transfers" => [invalid_transfer])
      bulk_request = described_class.from_json(attrs.to_json)

      expect(bulk_request).not_to be_valid
      expect(bulk_request.errors[:credit_transfers].first).to include("Invalid transaction with description => bad: Amount must be greater than zero")
    end
  end

  describe ".from_json" do
    it "returns an invalid object when JSON is blank" do
      bulk_request = described_class.from_json("")
      expect(bulk_request).not_to be_valid
    end

    it "returns an invalid object when JSON is malformed" do
      bulk_request = described_class.from_json("{invalid_json}")
      expect(bulk_request).not_to be_valid
    end

    it "returns a valid object when JSON is well-formed and has required fields" do
      bulk_request = described_class.from_json(valid_attributes.to_json)
      expect(bulk_request).to be_valid
      expect(bulk_request.organization_bic).to eq("BIC")
      expect(bulk_request.organization_iban).to eq("IBAN")
      expect(bulk_request.credit_transfers.size).to eq(1)
    end
  end
end
