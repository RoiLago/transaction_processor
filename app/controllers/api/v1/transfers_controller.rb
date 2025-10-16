module Api
  module V1
    class TransfersController < ApplicationController
      def bulk
        request_object = BulkTransferRequest.from_json(request.body.read)
        unless request_object.valid?
          return render json: { errors: request_object.errors.full_messages }, status: :unprocessable_content
        end

        service = TransferService.new(request_object)
        unless service.process
          return render json: { errors: service.errors }, status: :unprocessable_content
        end

        head :created
      end
    end
  end
end
