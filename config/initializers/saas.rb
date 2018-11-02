Saas.configure do |config|
  env = Rails.env.production? ? :production : :development
  rails_config = Rails.application.credentials[env]
  if rails_config && rails_config[:stripe]
    config.stripe_public_key = rails_config[:stripe][:public_key]
    config.stripe_secret_key = rails_config[:stripe][:secret_key]
  end
end