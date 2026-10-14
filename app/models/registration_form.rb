class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  INTERESTS = [
    "Karaoke", "Mental-health conversation", "Meeting people",
    "Games", "Food", "Photos / memories"
  ].freeze

  attribute :full_name, :string
  attribute :phone, :string
  attribute :programme, :string
  attribute :email, :string
  attribute :coming_with, :string
  attribute :interests, default: -> { [] }
  attribute :ticket_price, :integer

  attr_reader :normalized_phone

  before_validation :clean_up

  validates :full_name, presence: { message: "Please tell us your name." }
  validates :full_name, length: { minimum: 2, maximum: 80,
                                  too_short: "That name looks too short.",
                                  too_long: "That name is too long (80 characters max)." },
                        allow_blank: true

  validates :phone, presence: { message: "We need your phone number so we can find your ticket later." }
  validate  :phone_must_be_valid

  validates :programme, presence: { message: "Please tell us what you're studying." }
  validates :programme, length: { maximum: 100, too_long: "That's a bit long (100 characters max)." }, allow_blank: true

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "That email doesn't look right. You can also leave it blank." },
                    length: { maximum: 254 }, allow_blank: true

  validates :coming_with, length: { maximum: 100, too_long: "That's a bit long (100 characters max)." }, allow_blank: true
    validates :ticket_price, inclusion: { in: ->(_form) { Rails.configuration.x.event.ticket_prices },
                                        message: "Please choose a ticket price." }

  # What we keep between the form and the review page (Phase 3 will save this to the database instead).
  def to_session
    {
      "full_name" => full_name, "phone" => normalized_phone, "programme" => programme,
      "email" => email, "coming_with" => coming_with, "interests" => interests,
      "ticket_price" => ticket_price
    }
  end

  private

  def clean_up
    self.full_name   = full_name.to_s.squish
    self.programme   = programme.to_s.squish
    self.email       = email.to_s.squish.downcase
    self.coming_with = coming_with.to_s.squish
    self.interests   = Array(interests).map(&:to_s) & INTERESTS   # keep only known options
    @normalized_phone = PhoneNormalizer.call(phone)
  end

  def phone_must_be_valid
    return if phone.blank?  # "required" message already covers this
    errors.add(:phone, "That doesn't look like a Rwandan mobile number. Try something like 0788 123 456.") if normalized_phone.nil?
  end
end
