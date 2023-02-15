require_relative "boot"

# ============= reduce footprint only require needed 'railties'
# require "rails/all"
# =============================================================
# ref: https://iditect.com/article/activerecordconnectionnotestablished-in-rails-31-on-heroku.html
#=====
# https://github.com/rails/rails/issues/41106



require "action_controller/railtie"  
require "action_view/railtie"
require "active_model/railtie" 
require "active_storage/engine" 
require "action_mailer/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module A90Insurance
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.assets.precompile += %w(.jpg)

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
