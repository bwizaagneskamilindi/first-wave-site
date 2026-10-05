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

  # NEW: the person pressed "Confirm" on the review page. Save to the database.
  def confirm
    data = session[:pending_registration]
    return redirect_to(new_registration_path) if data.blank?

    registration = Registration.find_or_initialize_by(phone: data["phone"])

    unless registration.paid?
      # An unpaid registration with this phone can be updated and retried.
      registration.assign_attributes(
        data.slice("full_name", "programme", "email", "coming_with", "interests")
      )
      unless registration.save
        return redirect_to new_registration_path,
               alert: "Something went wrong saving your details. Please try again."
      end
    end

    session.delete(:pending_registration)
    redirect_to ticket_path(code: registration.ticket_code), status: :see_other
  end

  # NEW: for now a simple "you're on the list" page. Phase 4 turns it into the payment page.
  def show
    @event        = Rails.configuration.x.event
    @registration = Registration.find_by!(ticket_code: params[:code])
  end

  private

  def form_params
    params.require(:registration_form)
          .permit(:full_name, :phone, :programme, :email, :coming_with, interests: [])
  end

  def prefill
    data = session[:pending_registration]
    return {} if data.blank?
    data.merge("phone" => PhoneNormalizer.local(data["phone"]))
  end
end
