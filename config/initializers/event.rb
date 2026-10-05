# Loads config/event.yml once at startup.
# Anywhere in the app: Rails.configuration.x.event.venue
Rails.configuration.x.event = Rails.application.config_for(:event)
