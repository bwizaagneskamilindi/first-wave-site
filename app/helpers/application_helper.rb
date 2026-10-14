module ApplicationHelper
  # Opens Google Maps with directions to the venue's exact pin.
  # On iPhones it opens the Google Maps app if installed, otherwise Safari.
  def map_directions_url
    event = Rails.configuration.x.event
    "https://www.google.com/maps/dir/?api=1&destination=#{event.map_lat},#{event.map_lng}"
  end
end
