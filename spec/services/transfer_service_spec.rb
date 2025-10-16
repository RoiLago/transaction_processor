require "rails_helper"

RSpec.describe TransferService do
  let!(:account) { BankAccount.create!(organization_name: "Test Org", balance_cents: 12_000, iban: "IBAN1", bic: "BIC1") }

  let(:valid_transfer) do
    CreditTransferRequest.new(
      "amount" => "50.0",
      "currency" => "EUR",
      "counterparty_name" => "Alice",
      "counterparty_iban" => "CounterIBAN",
      "counterparty_bic" => "CounterBIC",
      "description" => "Payment"
    )
  end

  let(:bulk_request) do
    BulkTransferRequest.from_json(
      {
        "organization_bic" => account.bic,
        "organization_iban" => account.iban,
        "credit_transfers" => [valid_transfer]
      }.to_json)
  end

  subject(:service) { described_class.new(bulk_request) }

  describe "#process" do
    context "when valid" do
      it "inserts transfers and updates balance" do
        expect {
          expect(service.process).to eq(true)
        }.to change { Transaction.count }.by(1)

        transaction = Transaction.last
        expect(transaction.amount_cents).to eq(-5000)
        expect(transaction.amount_currency).to eq("EUR")

        expect(account.reload.balance_cents).to eq(7000)
      end
    end

    context "when insufficient funds" do
      before { account.update!(balance_cents: 10) }

      it "does not insert transfers and sets errors" do
        expect(service.process).to eq(false)
        expect(service.errors).to include("Insufficient funds")
        expect(Transaction.count).to eq(0)
        expect(account.reload.balance_cents).to eq(10)
      end
    end

    context "when account not found" do
      let(:bulk_request) do
        BulkTransferRequest.from_json(
          {
            "organization_bic" => "UNKNOWN",
            "organization_iban" => "UNKNOWN",
            "credit_transfers" => [ valid_transfer ]
          }.to_json)
      end

      it "fails with proper error" do
        expect(service.process).to eq(false)
        expect(service.errors).to include("Bank account not found")
      end
    end

    context "when an unexpected exception occurs" do
      before do
        allow(Transaction).to receive(:insert_all!).and_raise(StandardError, "DB down")
      end

      it "sets errors and rolls back" do
        expect(service.process).to eq(false)
        expect(service.errors.first).to include("Unexpected error")
        expect(account.reload.balance_cents).to eq(12_000)
      end
    end

    context "batch insert with multiple transfers" do
      before do
        stub_const("TransferService::BATCH_SIZE", 5)
      end

      let(:bulk_request) do
        BulkTransferRequest.from_json(
          {
            "organization_bic" => account.bic,
            "organization_iban" => account.iban,
            "credit_transfers" => 10.times.map do |i|
              {
                "amount" => "1.0",
                "currency" => "EUR",
                "counterparty_name" => "Counterparty #{i}",
                "counterparty_bic" => "BIC#{i}",
                "counterparty_iban" => "IBAN#{i}",
                "description" => "Transfer #{i}"
              }
            end
          }.to_json)
      end

      it "successfully inserts all transfers in batches and updates balance" do
        expect(service.process).to eq(true)
        expect(service.errors).to be_empty
        expect(Transaction.count).to eq(10)
        expect(account.reload.balance_cents).to eq(11_000)
      end

      context 'when batch fails' do
        before do
          call_count = 0

          allow(Transaction).to receive(:insert_all!).and_wrap_original do |m, *args|
            call_count += 1
            raise StandardError, "Batch insert failed" if call_count == 2
            m.call(*args)
          end
        end

        it "rolls back" do
          expect(service.process).to eq(false)
          expect(service.errors.first).to include("Batch insert failed")
          expect(Transaction.count).to eq(0)
          expect(account.reload.balance_cents).to eq(12_000)
        end
      end
    end
  end
end
