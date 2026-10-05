class Payment < ApplicationRecord
  STATUSES = %w[pending successful failed].freeze

  belongs_to :registration

  before_validation :normalize_payer_phone
  before_validation :set_reference, on: :create

  validates :payer_phone, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate  :payer_must_be_mtn

  def pending?    = status == "pending"
  def successful? = status == "successful"
  def failed?     = status == "failed"

  # Called when MTN confirms the money arrived. Both changes happen together or not at all.
  def mark_successful!
    return if successful?

    transaction do
      update!(status: "successful")
      registration.update!(status: "paid")
    end
  end

  def mark_failed!(message = nil)
    return unless pending?

    update!(status: "failed", provider_message: message)
  end

  # Ask MTN what happened to this payment and update our records.
  def refresh_from_gateway!
    return unless pending?

    result = MomoGateway.fetch_status(self)
    case result[:status]
    when "SUCCESSFUL" then mark_successful!
    when "FAILED"     then mark_failed!(result[:reason])
    end
  rescue MomoGateway::Error, KeyError => e
    Rails.logger.warn "[Payment #{reference_id}] status check failed: #{e.message}"
  end

  def to_param = reference_id

  private

  def normalize_payer_phone
    digits = PhoneNormalizer.call(payer_phone).to_s.gsub(/\D/, "")
    self.payer_phone = digits if digits.present?
  end

  def set_reference
    self.reference_id ||= SecureRandom.uuid
  end

  # MTN MoMo numbers in Rwanda start with 078 or 079 (250 78x / 250 79x)
  def payer_must_be_mtn
    return if payer_phone.blank?
    unless payer_phone.match?(/\A250(78|79)\d{7}\z/)
      errors.add(:payer_phone, "Please use an MTN MoMo number (starts with 078 or 079).")
    end
  end
end
