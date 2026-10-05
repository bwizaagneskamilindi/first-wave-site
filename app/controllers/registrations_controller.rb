class RegistrationsController < ApplicationController
  def new
    @event = Rails.configuration.x.event
    @form  = RegistrationForm.new(prefill)
  end

  def create
    @event = Rails.configuration.x.event
    @form  = RegistrationForm.new(form_params)

    if @form.valid?
      session[:pending_registration] = @form.to_session
      redirect_to review_registration_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def review
    @data = session[:pending_registration]
    redirect_to new_registration_path if @data.blank?
  end

  private

  # "strong parameters": only these fields are accepted from the browser.
  def form_params
    params.require(:registration_form)
          .permit(:full_name, :phone, :programme, :email, :coming_with, interests: [])
  end

  # If someone clicks "Edit details", bring their answers back.
  def prefill
    data = session[:pending_registration]
    return {} if data.blank?
    data.merge("phone" => PhoneNormalizer.local(data["phone"]))
  end
end
