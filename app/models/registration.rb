class Registration < ApplicationRecord
  has_many :payments, dependent: :destroy
  STATUSES   = %w[pending paid cancelled].freeze
  CODE_CHARS = %w[A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9].freeze

  before_validation :normalize_phone
  before_validation :set_price, on: :create
  before_validation :set_ticket_code, on: :create

  validates :full_name,   presence: true, length: { maximum: 80 }
  validates :programme,   presence: true, length: { maximum: 100 }
  validates :coming_with, length: { maximum: 100 }
  validates :email, allow_blank: true, length: { maximum: 254 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :paid, -> { where(status: "paid") }

  def self.event
    Rails.configuration.x.event
  end

  # The price the NEXT person will pay. The server decides, never the browser.
  def self.current_price
    early_bird_open? ? event.early_bird_price : event.regular_price
  end

  def self.early_bird_open?
    where.not(status: "cancelled").count < event.early_bird_limit
  end

  def paid? = status == "paid"

  private

  def normalize_phone
    self.phone = PhoneNormalizer.call(phone) || phone
  end

  def set_price
    self.early_bird = self.class.early_bird_open?
    self.price = early_bird ? self.class.event.early_bird_price : self.class.event.regular_price
  end

  def set_ticket_code
    return if ticket_code.present?
    loop do
      self.ticket_code = "FW" + Array.new(6) { CODE_CHARS.sample(random: SecureRandom) }.join
      break unless self.class.exists?(ticket_code: ticket_code)
    end
  end
end
