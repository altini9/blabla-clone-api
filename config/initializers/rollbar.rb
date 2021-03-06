# frozen_string_literal: true

if Rails.env.production?
  Rollbar.configure do |config|
    config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]
    config.environment = ENV["ROLLBAR_ENV"] || Rails.env
  end
end
