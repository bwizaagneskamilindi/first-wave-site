module Organizer
  class BaseController < ApplicationController
    before_action :require_organizer
    helper_method :current_organizer

    private

    # Returns { "the-secret-key" => "agnes", ... } from the ORGANIZER_KEYS secret.
    def organizer_keys
      ENV["ORGANIZER_KEYS"].to_s.split(",").filter_map do |pair|
        name, key = pair.strip.split(":", 2)
        [key.strip, name.strip] if name.present? && key.present?
      end.to_h
    end

    # Which organizer does this key belong to? nil if it matches nobody.
    def organizer_name_for(candidate)
      return nil if candidate.blank?

      match = organizer_keys.find { |key, _name| ActiveSupport::SecurityUtils.secure_compare(key, candidate.to_s) }
      match&.last
    end

    def current_organizer
      @current_organizer
    end

    def require_organizer
      if organizer_keys.empty?
        render plain: "Organizer access is not set up yet.", status: :service_unavailable
        return
      end

      # 1) First visit with a personal link: remember them, then clean the key out of the address bar
      if params[:access_key].present?
        if organizer_name_for(params[:access_key])
          cookies.signed[:organizer_key] = {
            value: params[:access_key].to_s,
            expires: 30.days.from_now,
            httponly: true,
            same_site: :lax,
            secure: Rails.env.production?
          }
          redirect_to request.path, status: :see_other
        else
          deny_access
        end
        return
      end

      # 2) Later visits: the cookie must still match a key that is on the list today
      @current_organizer = organizer_name_for(cookies.signed[:organizer_key])
      deny_access unless @current_organizer
    end

    def deny_access
      render plain: "This page is for organizers. Please open your personal organizer link.",
             status: :unauthorized
    end
  end
end
