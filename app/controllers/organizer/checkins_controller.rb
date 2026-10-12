module Organizer
  class CheckinsController < BaseController
    before_action :load_registration, only: %i[show create destroy]

    # The lookup page: type a ticket code, name or phone number
    def index
      @query = params[:q].to_s.strip

      # A full ticket code goes straight to that ticket
      if @query.match?(/\AFW[A-Z0-9]{6}\z/i)
        registration = Registration.find_by(ticket_code: @query.upcase)
        return redirect_to scan_path(code: registration.ticket_code) if registration
      end

      @matches = if @query.present?
        Registration.where.not(status: "cancelled").search(@query).order(:full_name).limit(20)
      else
        []
      end
    end

    # What the QR code opens: shows the result. Looking at this page changes nothing.
    def show; end

    # The "Check in" button
    def create
      @registration.check_in!(current_organizer)   # does nothing if already checked in or unpaid
      redirect_to scan_path(code: @registration.ticket_code), status: :see_other
    end

    # The "Undo" button
    def destroy
      @registration.undo_check_in!
      redirect_to scan_path(code: @registration.ticket_code), status: :see_other
    end

    private

    def load_registration
      @registration = Registration.find_by(ticket_code: params[:code].to_s.upcase)
      render :not_found, status: :not_found unless @registration
    end
  end
end
