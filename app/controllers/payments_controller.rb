class PaymentsController < ApplicationController
  before_action :load_event

  def new
    @registration = find_registration
    return redirect_to(ticket_path(code: @registration.ticket_code)) if @registration.paid?

    @payment = Payment.new(payer_phone: PhoneNormalizer.local(@registration.phone))
  end

  def create
    @registration = find_registration
    return redirect_to(ticket_path(code: @registration.ticket_code)) if @registration.paid?

    # The amount comes from the registration saved on the server, never from the form.
    @payment = @registration.payments.build(
      payer_phone: params.dig(:payment, :payer_phone),
      amount: @registration.price,
      currency: @event.currency
    )

    if @payment.save
      begin
        MomoGateway.request_to_pay(@payment)
      rescue MomoGateway::Error, KeyError => e
        Rails.logger.error "[Payment #{@payment.reference_id}] request failed: #{e.message}"
        @payment.mark_failed!("We couldn't reach the payment service.")
      end
      redirect_to payment_path(reference: @payment.reference_id), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @payment      = Payment.find_by!(reference_id: params[:reference])
    @registration = @payment.registration

    @payment.refresh_from_gateway! if @payment.pending?   # ask MTN every time the page loads

    redirect_to ticket_path(code: @registration.ticket_code) if @payment.successful?
  end

  # DEVELOPMENT ONLY: pretend MTN answered, so we can test without MTN.
  def simulate
    return head(:not_found) unless Rails.env.development?

    payment = Payment.find_by!(reference_id: params[:reference])
    case params[:outcome]
    when "success" then payment.mark_successful!
    when "failure" then payment.mark_failed!("Simulated failure")
    end
    redirect_to payment_path(reference: payment.reference_id), status: :see_other
  end

  private

  def load_event
    @event = Rails.configuration.x.event
  end

  def find_registration
    Registration.find_by!(ticket_code: params[:code])
  end
end
