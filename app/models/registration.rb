class Registration < ApplicationRecord
  has_many :payments, dependent: :destroy

  STATUSES   = %w[pending submitted paid cancelled].freeze
  CODE_CHARS = %w[A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9].freeze

  before_validation :normalize_phone
  before_validation :normalize_transaction_id
  before_validation :set_ticket_code, on: :create

  validates :full_name,   presence: true, length: { maximum: 80 }
  validates :programme,   presence: true, length: { maximum: 100 }
  validates :coming_with, length: { maximum: 100 }
  validates :email, allow_blank: true, length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :momo_transaction_id,
            allow_nil: true,
            uniqueness: { message: "That transaction ID was already used. Please check it in your MoMo SMS." },
            format: { with: /\A[A-Z0-9]{6,20}\z/,
                      message: "That doesn't look like a MoMo transaction ID. Copy it from your confirmation SMS." }
  validates :price, presence: true
  validates :price, inclusion: { in: ->(_r) { Rails.configuration.x.event.ticket_prices } },
                    if: :will_save_change_to_price?                    

  scope :paid, -> { where(status: "paid") }
  scope :checked_in, -> { where.not(checked_in_at: nil) }


  def self.event
    Rails.configuration.x.event
  end

  # Finds registrations by name, programme, ticket code or phone number.
  def self.search(query)
    query = query.to_s.strip
    return all if query.blank?

    term = "%#{sanitize_sql_like(query.downcase)}%"

    # Phones are stored like 250788123456, so "0788 123 456" is turned into "788123456".
    digits = query.gsub(/\D/, "").sub(/\A(250|0)/, "")

    if digits.length >= 3
      where(
        "LOWER(full_name) LIKE :t OR LOWER(programme) LIKE :t OR LOWER(ticket_code) LIKE :t OR phone LIKE :p",
        t: term, p: "%#{digits}%"
      )
    else
      where(
        "LOWER(full_name) LIKE :t OR LOWER(programme) LIKE :t OR LOWER(ticket_code) LIKE :t",
        t: term
      )
    end
  end

  def paid?             = status == "paid"
  def submitted?        = status == "submitted"
  def cancelled?        = status == "cancelled"
  def awaiting_payment? = %w[pending submitted].include?(status)
  def checked_in?       = checked_in_at.present?

  # ---- Manual MoMo payment ----

  # The attendee typed their transaction ID. Returns true if it was accepted.
  def submit_manual_payment(transaction_id)
    return false unless awaiting_payment?

    self.momo_transaction_id = transaction_id
    valid?   # cleans the ID and checks its format and that it is unused
    if momo_transaction_id.blank?
      errors.add(:momo_transaction_id, "Please type the transaction ID from your MoMo confirmation SMS.")
    end
    return false if errors.any?

    update(status: "submitted", payment_submitted_at: Time.current, payment_method: "manual")
  end

  # An organizer confirmed the money arrived (also used for payments in person).
  def mark_paid_manually!(organizer_name)
    return false unless awaiting_payment?

    update!(status: "paid", payment_method: "manual", confirmed_by: organizer_name)
  end

  # An organizer could not find the payment: send the person back to try again.
  def reject_manual_payment!
    return false unless submitted?

    update!(status: "pending", momo_transaction_id: nil, payment_submitted_at: nil, payment_method: nil)
  end

  # ---- Check-in ----

  # Checks the person in. Returns true only if THIS call did it:
  # it fails for unpaid tickets and for tickets already checked in.
  def check_in!(organizer_name)
    now = Time.current
    self.class.where(id: id, status: "paid", checked_in_at: nil)
              .update_all(checked_in_at: now, checked_in_by: organizer_name, updated_at: now) == 1
  end

  def undo_check_in!
    update!(checked_in_at: nil, checked_in_by: nil)
  end

  private

  def normalize_phone
    self.phone = PhoneNormalizer.call(phone) || phone
  end

  # "12 34-56" becomes "123456"; an empty box becomes nil
  def normalize_transaction_id
    self.momo_transaction_id = momo_transaction_id.to_s.gsub(/[\s-]/, "").upcase.presence
  end

  def set_ticket_code
    return if ticket_code.present?
    loop do
      self.ticket_code = "FW" + Array.new(6) { CODE_CHARS.sample(random: SecureRandom) }.join
      break unless self.class.exists?(ticket_code: ticket_code)
    end
  end
end
