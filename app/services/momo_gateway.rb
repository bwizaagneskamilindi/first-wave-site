require "net/http"
require "json"

class MomoGateway
  class Error < StandardError; end

  def self.request_to_pay(payment) = new.request_to_pay(payment)
  def self.fetch_status(payment)   = new.fetch_status(payment)

  def initialize
    @base_url         = ENV.fetch("MOMO_BASE_URL", "https://sandbox.momodeveloper.mtn.com")
    @environment      = ENV.fetch("MOMO_ENVIRONMENT", "sandbox")
    @currency         = ENV.fetch("MOMO_CURRENCY", "EUR")   # the sandbox only accepts EUR
    @subscription_key = ENV.fetch("MOMO_SUBSCRIPTION_KEY")
    @api_user         = ENV.fetch("MOMO_API_USER")
    @api_key          = ENV.fetch("MOMO_API_KEY")
  end

  # Ask MTN to send a payment prompt to the payer's phone.
  def request_to_pay(payment)
    body = {
      amount: payment.amount.to_s,
      currency: @currency,
      externalId: payment.registration.ticket_code,
      payer: { partyIdType: "MSISDN", partyId: payer_id(payment) },
      payerMessage: "First Wave ticket",
      payeeNote: "Ticket #{payment.registration.ticket_code}"
    }

    headers = { "X-Reference-Id" => payment.reference_id, "X-Target-Environment" => @environment }
    callback = callback_url(payment)
    headers["X-Callback-Url"] = callback if callback

    response = call(Net::HTTP::Post, "/collection/v1_0/requesttopay", body: body, headers: headers)
    raise Error, "MTN did not accept the request (HTTP #{response.code}): #{response.body}" unless response.code == "202"
  end

  # Ask MTN what happened. Returns { status: "PENDING" | "SUCCESSFUL" | "FAILED", reason: "..." }
  def fetch_status(payment)
    response = call(
      Net::HTTP::Get, "/collection/v1_0/requesttopay/#{payment.reference_id}",
      headers: { "X-Target-Environment" => @environment }
    )
    raise Error, "Status check failed (HTTP #{response.code})" unless response.code == "200"

    json = JSON.parse(response.body)
    reason = json["reason"]
    reason = reason["message"] || reason["code"] if reason.is_a?(Hash)
    { status: json["status"], reason: reason.to_s.presence }
  end

  private

  # Callbacks are only switched on when MOMO_CALLBACK_HOST is set. That must be the
  # same host the API user was registered with (see `bin/rails momo:setup_sandbox`).
  def callback_url(payment)
    host = ENV["MOMO_CALLBACK_HOST"].presence
    "https://#{host}/webhooks/momo/#{payment.reference_id}" if host
  end

  # In the sandbox you can set MOMO_TEST_PAYER to one of MTN's special test numbers
  # (e.g. 46733123450 makes the payment FAIL). Real numbers are used otherwise.
  def payer_id(payment)
    test_number = ENV["MOMO_TEST_PAYER"].presence
    @environment == "sandbox" && test_number ? test_number : payment.payer_phone
  end

  def access_token
    uri = URI.join(@base_url, "/collection/token/")
    req = Net::HTTP::Post.new(uri)
    req.basic_auth(@api_user, @api_key)
    req["Ocp-Apim-Subscription-Key"] = @subscription_key
    response = http_start(uri) { |http| http.request(req) }
    raise Error, "Could not get an MTN token (HTTP #{response.code})" unless response.code == "200"

    JSON.parse(response.body)["access_token"]
  end

  def call(request_class, path, body: nil, headers: {})
    uri = URI.join(@base_url, path)
    req = request_class.new(uri)
    req["Authorization"]             = "Bearer #{access_token}"
    req["Ocp-Apim-Subscription-Key"] = @subscription_key
    req["Content-Type"]              = "application/json"
    headers.each { |name, value| req[name] = value }
    req.body = body.to_json if body

    http_start(uri) { |http| http.request(req) }
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
    raise Error, "Could not reach MTN: #{e.class}"
  end

  def http_start(uri, &block)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 5, read_timeout: 15, &block)
  end
end
