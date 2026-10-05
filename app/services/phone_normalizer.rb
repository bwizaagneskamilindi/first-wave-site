class PhoneNormalizer
  VALID_MOBILE = /\A2507[2389]\d{7}\z/  # Airtel (72, 73) and MTN (78, 79)
  MTN_MOBILE   = /\A2507[89]\d{7}\z/    # MTN only

  # Returns "250788123456" or nil if the input isn't a valid Rwandan mobile.
  def self.call(input)
    digits = input.to_s.gsub(/\D/, "").delete_prefix("00")
    digits = "250#{digits.delete_prefix('0')}" unless digits.start_with?("250")
    digits.match?(VALID_MOBILE) ? digits : nil
  end

  def self.mtn?(canonical)
    canonical.to_s.match?(MTN_MOBILE)
  end

  # "250788123456" -> "0788 123 456" (for showing back to people)
  def self.local(canonical)
    d = canonical.to_s
    return d unless d.match?(VALID_MOBILE)
    "0#{d[3, 3]} #{d[6, 3]} #{d[9, 3]}"
  end
end
