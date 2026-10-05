require "test_helper"

class PhoneNormalizerTest < ActiveSupport::TestCase
  test "accepts the common ways of typing a Rwandan number" do
    ["0788123456", "788123456", "+250 788 123 456", "250788123456", "0788-123-456", "00250788123456"].each do |input|
      assert_equal "250788123456", PhoneNormalizer.call(input), "failed for #{input}"
    end
  end

  test "rejects invalid numbers" do
    [nil, "", "12345", "0688123456", "078812345", "07881234567"].each do |input|
      assert_nil PhoneNormalizer.call(input), "should reject #{input.inspect}"
    end
  end

  test "tells MTN from Airtel" do
    assert PhoneNormalizer.mtn?("250788123456")
    assert_not PhoneNormalizer.mtn?("250728123456")
  end

  test "formats for display" do
    assert_equal "0788 123 456", PhoneNormalizer.local("250788123456")
  end
end
