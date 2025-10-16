require 'rails_helper'

RSpec.describe Api::V1::TransfersController, type: :controller do
  describe "POST #bulk" do
    let(:json_file) { Rails.root.join('spec', 'fixtures', 'sample1.json') }
    let(:json_body) { File.read(json_file) }

    let(:transfer_service) { double("TransferService") }
    let(:request) { double("BulkTransferRequest") }

    before do
      allow(TransferService).to receive(:new).and_return(transfer_service)
      allow(transfer_service).to receive(:process).and_return(true)

      allow(BulkTransferRequest).to receive(:new).and_return(request)
      allow(request).to receive(:valid?).and_return(true)
    end

    context "with valid JSON" do
      it "returns 201" do
        post :bulk, body: json_body

        expect(response).to have_http_status(:created)
      end

      it "calls service process" do
        post :bulk, body: json_body

        expect(transfer_service).to have_received(:process)
      end
    end

    context "with invalid body" do
      let(:json_body) { '{"invalid": "json"' }

      before do
        errors = instance_double(ActiveModel::Errors, full_messages: [ 'JSON error' ], add: nil)
        request_object = instance_double(BulkTransferRequest, valid?: false, errors: errors)
        allow(BulkTransferRequest).to receive(:new).and_return(request_object)
      end

      it "returns 422" do
        post :bulk, body: nil

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).not_to be_empty
      end
    end

    context "when the request is not valid" do
      before do
        errors = instance_double(ActiveModel::Errors, full_messages: [ 'Validation error' ])
        request_object = instance_double(BulkTransferRequest, valid?: false, errors: errors)
        allow(BulkTransferRequest).to receive(:new).and_return(request_object)
      end

      it "returns 422" do
        post :bulk, body: json_body

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Validation error")
      end
    end

    context "when the service processing fails" do
      before do
        allow(transfer_service).to receive(:process).and_return(false)
        allow(transfer_service).to receive(:errors).and_return([ 'Processing error' ])
      end

      it "returns 422" do
        post :bulk, body: json_body

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Processing error")
      end
    end
  end
end
