namespace :momo do
  desc "Create a MoMo SANDBOX API user and API key (sandbox only)"
  task setup_sandbox: :environment do
    require "net/http"
    require "json"
    require "securerandom"

    subscription_key = ENV["MOMO_SUBSCRIPTION_KEY"].presence ||
                       abort("Set MOMO_SUBSCRIPTION_KEY first.")
    base          = ENV.fetch("MOMO_BASE_URL", "https://sandbox.momodeveloper.mtn.com")
    callback_host = ENV["MOMO_CALLBACK_HOST"].presence || "example.com"
    user_id       = SecureRandom.uuid

    send_post = lambda do |path, headers, body|
      uri = URI.join(base, path)
      req = Net::HTTP::Post.new(uri)
      req["Ocp-Apim-Subscription-Key"] = subscription_key
      req["Content-Type"] = "application/json"
      headers.each { |k, v| req[k] = v }
      req.body = body.to_json if body
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    end

    # 1) Create the API user, registered for our callback host
    res = send_post.call("/v1_0/apiuser", { "X-Reference-Id" => user_id }, { providerCallbackHost: callback_host })
    abort("Creating the API user failed: #{res.code} #{res.body}") unless res.code == "201"

    # 2) Create its API key
    res = send_post.call("/v1_0/apiuser/#{user_id}/apikey", {}, nil)
    abort("Creating the API key failed: #{res.code} #{res.body}") unless %w[200 201].include?(res.code)
    api_key = JSON.parse(res.body)["apiKey"]

    puts "Done. Save these as secrets:"
    puts "MOMO_API_USER=#{user_id}"
    puts "MOMO_API_KEY=#{api_key}"
    puts "MOMO_CALLBACK_HOST=#{callback_host}"
  end

  desc "Safety net: recheck payments still pending with MTN"
  task reconcile: :environment do
    pending = Payment.where(status: "pending").where(created_at: 2.days.ago..2.minutes.ago)
    puts "Checking #{pending.count} pending payment(s)..."

    pending.find_each do |payment|
      payment.refresh_from_gateway!
      puts "#{payment.reference_id}: #{payment.reload.status}"
    end
  end
end
