# MTN calls this URL when a payment finishes.
# We never trust what the call says: we only use it as a signal, then ask MTN directly.
class MomoWebhooksController < ActionController::Base
  # MTN is not a browser, so it can't send a form token.
  skip_forgery_protection

  def update
    payment = Payment.find_by(reference_id: params[:reference])
    return head(:not_found) unless payment

    Rails.logger.info "[MoMo webhook] callback received for #{payment.reference_id}"
    payment.refresh_from_gateway!   # asks MTN for the real status
    head :ok
  end
end
