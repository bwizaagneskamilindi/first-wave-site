module Organizer
  class PaymentsController < BaseController
    before_action :load_registration, only: %i[confirm reject]

    # The "Verify payments" page
    def index
      @submitted = Registration.where(status: "submitted").order(:payment_submitted_at)
    end

    def confirm
      @registration.mark_paid_manually!(current_organizer)
      redirect_back_or_to organizer_payments_path, status: :see_other
    end

    def reject
      @registration.reject_manual_payment!
      redirect_back_or_to organizer_payments_path, status: :see_other
    end

    private

    def load_registration
      @registration = Registration.find_by!(ticket_code: params[:code].to_s.upcase)
    end
  end
end
