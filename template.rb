require "fileutils"
require "shellwords"

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("jumpstart-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/dvanderbeek/jumpstart.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{jumpstart/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_gems
  gem 'administrate', '~> 0.10.0'
  gem 'bootstrap', '~> 4.1', '>= 4.1.1'
  gem 'data-confirm-modal', '~> 1.6', '>= 1.6.2'
  gem 'devise', '~> 4.4', '>= 4.4.3'
  gem 'devise-bootstrapped', github: 'excid3/devise-bootstrapped', branch: 'bootstrap4'
  gem 'devise_masquerade', '~> 0.6.2'
  gem 'font-awesome-sass', '~> 5.0', '>= 5.0.13'
  gem 'foreman', '~> 0.84.0'
  gem 'gravatar_image_tag', github: 'mdeering/gravatar_image_tag'
  gem 'jquery-rails', '~> 4.3.1'
  gem 'local_time', '~> 2.0', '>= 2.0.1'
  gem 'mini_magick', '~> 4.8'
  gem 'name_of_person', '~> 1.0'
  gem 'omniauth-facebook', '~> 5.0'
  gem 'omniauth-github', '~> 1.3'
  gem 'omniauth-twitter', '~> 1.4'
  gem 'saas', github: 'dvanderbeek/saas', branch: 'master'
  gem 'sidekiq', '~> 5.1', '>= 5.1.3'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.1'
  gem 'webpacker', '~> 3.5', '>= 3.5.3'
  gem 'whenever', require: false
end

def set_application_name
  # Add Application Name to Config
  environment "config.application_name = Rails.application.class.parent_name"

  # Announce the user where he can change the application name in the future.
  puts "You can change application name inside: ./config/application.rb"
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  route "root to: 'home#index'"

  # Devise notices are installed via Bootstrap
  generate "devise:views:bootstrapped"

  # Create Devise User
  generate :devise, "User",
           "first_name",
           "last_name",
           "announcements_last_read_at:datetime",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  requirement = Gem::Requirement.new("> 5.2")
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  if requirement.satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "omniauthable, :masqueradable, :", after: "devise :")
end

def add_bootstrap
  # Remove Application CSS
  run "rm app/assets/stylesheets/application.css"

  # Add Bootstrap JS
  insert_into_file(
    "app/assets/javascripts/application.js",
    "\n//= require jquery\n//= require popper\n//= require bootstrap\n//= require data-confirm-modal\n//= require local-time",
    after: "//= require rails-ujs"
  )
end

def copy_templates
  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true

  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end

def add_webpack
  rails_command 'webpacker:install'
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  insert_into_file "config/routes.rb",
    "  authenticate :user, lambda { |u| u.admin? } do\n    mount Sidekiq::Web => '/sidekiq'\n  end\n\n",
    after: "Rails.application.routes.draw do\n"
end

def add_foreman
  copy_file "Procfile"
end

def add_announcements
  generate "model Announcement published_at:datetime announcement_type name description:text"
  route "resources :announcements, only: [:index]"
end

def add_accounts
  generate "model Account name owner:belongs_to"

  migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
  gsub_file migration, /foreign_key: true/, "foreign_key: { to_table: :users }, type: :uuid"

  route "resource :account, only: [:edit, :update]"
end

def add_account_to_users
  generate "migration add_account_to_users account:belongs_to"
end

def add_administrate
  generate "administrate:install"

  gsub_file "app/dashboards/announcement_dashboard.rb",
    /announcement_type: Field::String/,
    "announcement_type: Field::Select.with_options(collection: Announcement::TYPES)"

  gsub_file "app/dashboards/user_dashboard.rb",
    /email: Field::String/,
    "email: Field::String,\n    password: Field::String.with_options(searchable: false)"

  gsub_file "app/dashboards/user_dashboard.rb",
    /FORM_ATTRIBUTES = \[/,
    "FORM_ATTRIBUTES = [\n    :password,"

  gsub_file "app/dashboards/user_dashboard.rb",
    /owned_account: Field::HasOne/,
    "owned_account: Field::HasOne.with_options(class_name: Account.name)"

  gsub_file "app/dashboards/account_dashboard.rb",
    /:owner_id,\n\s*/,
    ""

  gsub_file "app/controllers/admin/application_controller.rb",
    /# TODO Add authentication logic here\./,
    "redirect_to '/', alert: 'Not authorized.' unless user_signed_in? && current_user.admin?"
end

def add_app_helpers_to_administrate
  environment do <<-RUBY
    # Expose our application's helpers to Administrate
    config.to_prepare do
      Administrate::ApplicationController.helper #{@app_name.camelize}::Application.helpers
    end
  RUBY
  end
end

def replace_dashboards
  copy_file "templates/account_dashboard.rb", "app/dashboards/account_dashboard.rb", force: true
  copy_file "templates/user_dashboard.rb", "app/dashboards/user_dashboard.rb", force: true
end

def add_multiple_authentication
    insert_into_file "config/routes.rb",
    ', controllers: { omniauth_callbacks: "users/omniauth_callbacks" }',
    after: "  devise_for :users"

    generate "model Service user:references provider uid access_token access_token_secret refresh_token expires_at:datetime auth:text"

    template = """
  if Rails.application.secrets.facebook_app_id.present? && Rails.application.secrets.facebook_app_secret.present?
    config.omniauth :facebook, Rails.application.secrets.facebook_app_id, Rails.application.secrets.facebook_app_secret, scope: 'email,user_posts'
  end

  if Rails.application.secrets.twitter_app_id.present? && Rails.application.secrets.twitter_app_secret.present?
    config.omniauth :twitter, Rails.application.secrets.twitter_app_id, Rails.application.secrets.twitter_app_secret
  end

  if Rails.application.secrets.github_app_id.present? && Rails.application.secrets.github_app_secret.present?
    config.omniauth :github, Rails.application.secrets.github_app_id, Rails.application.secrets.github_app_secret
  end
    """.strip

    insert_into_file "config/initializers/devise.rb", "  " + template + "\n\n",
          before: "  # ==> Warden configuration"
end

def uuid_foreign_keys
  insert_into_file(
    Dir["db/migrate/**/*add_account_to_users.rb"].first,
    ", type: :uuid",
    after: "foreign_key: true"
  )

  insert_into_file(
    Dir["db/migrate/**/*create_services.rb"].first,
    ", type: :uuid",
    after: "foreign_key: true"
  )
end

def add_whenever
  run "wheneverize ."
end

def stop_spring
  run "spring stop"
end

def add_sitemap
  rails_command "sitemap:install"
end

def add_pgcrypto
  generate "migration enable_pgcrypto_extension"

  insert_into_file(
    Dir["db/migrate/**/*enable_pgcrypto_extension.rb"].first,
    "\n    enable_extension 'pgcrypto'",
    after: "def change"
  )

  environment do <<-RUBY
    # Use UUID's for primary keys
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
  RUBY
  end
end

def add_saas
  rails_command "saas:install:migrations"
  route "mount Saas::Engine, at: '/saas'"
end

# Main setup
add_template_repository_to_source_path

add_gems

after_bundle do
  set_application_name
  stop_spring
  add_pgcrypto
  add_users
  add_saas
  add_bootstrap
  add_sidekiq
  add_foreman
  add_webpack
  add_announcements
  add_accounts
  add_account_to_users
  add_multiple_authentication
  uuid_foreign_keys

  copy_templates

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"

  # Migrations must be done before this
  add_administrate

  add_app_helpers_to_administrate
  replace_dashboards

  add_whenever

  add_sitemap


  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
