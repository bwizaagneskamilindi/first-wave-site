class PagesController < ApplicationController
  def home
    @event = Rails.configuration.x.event
  end
end
