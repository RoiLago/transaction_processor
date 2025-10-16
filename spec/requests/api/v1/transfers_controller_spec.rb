require 'rails_helper'

RSpec.describe Api::V1::TransfersController, type: :controller do
  describe "POST #bulk_create" do
    let(:json_file) { Rails.root.join('spec', 'fixtures', 'sample1.json') }
    let(:json_body) { File.read(json_file) }

    context "with valid JSON" do
      it "returns 201 and creates transfers" do
        request.headers["Content-Type"] = "application/json"

        expect {
          post :bulk_create, body: json_body
        }.to change(Transfer, :count).by_at_least(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid JSON" do
      let(:json_body) { '{"invalid": "json"' } # malformed

      it "returns 422" do
        request.headers["Content-Type"] = "application/json"

        post :bulk_create, body: json_body

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).not_to be_empty
      end
    end

    context "with insufficient funds" do
      before do
        # Make sure the account balance is lower than total transfers in fixture
        account = BankAccount.find_by(iban: "FR10474608000002006107XXXXX")
        account.update!(balance_cents: 0) if account
      end

      it "returns 422" do
        request.headers["Content-Type"] = "application/json"

        post :bulk_create, body: json_body

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Insufficient funds")
      end
    end
  end
end
