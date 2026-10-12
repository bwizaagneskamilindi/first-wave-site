# The attendee submits their MoMo transaction ID.
class ManualPaymentsController < ApplicationController
  def create
    @event        = Rails.configuration.x.event
    @registration = Registration.find_by!(ticket_code: params[:code])

    unless @registration.awaiting_payment?
      return redirect_to ticket_path(code: @registration.ticket_code), status: :see_other
    end

    if @registration.submit_manual_payment(params.dig(:registration, :momo_transaction_id))
      redirect_to ticket_path(code: @registration.ticket_code), status: :see_other
    else
      render "registrations/show", status: :unprocessable_entity
    end
  end
end
