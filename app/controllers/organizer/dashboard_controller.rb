module Organizer
  class DashboardController < BaseController
    STATUS_FILTERS = %w[paid pending].freeze

    def index
      @event = Rails.configuration.x.event

      active = Registration.where.not(status: "cancelled")
      @total      = active.count
      @paid       = Registration.paid.count
      @pending    = Registration.where(status: "pending").count
      @revenue    = Registration.paid.sum(:price)
      @early_left = [@event.early_bird_limit - @total, 0].max
      @checked_in = Registration.checked_in.count

      @status = params[:status].presence_in(STATUS_FILTERS)
      @query  = params[:q].to_s.strip

      scope = active.order(created_at: :desc)
      scope = scope.where(status: @status) if @status
      scope = scope.search(@query) if @query.present?

      @registrations = scope.limit(300)
    end
  end
end
