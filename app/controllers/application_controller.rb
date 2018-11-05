class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :masquerade_user!

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :account_name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end

    def current_subscriber
      # For SaaS gem (Stripe subscription billing)
      current_user.account
    end
end
