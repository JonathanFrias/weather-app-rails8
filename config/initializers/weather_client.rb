require "weather_client"

case Rails.env.to_s
when "production", "development"
  WEATHER_CLIENT = WeatherClient.new(api_key: Rails.application.credentials[Rails.env.to_s]["openweathermap_api_key"])
when "test"
  require_relative "../../spec/support/weather_client_test"
  WEATHER_CLIENT = WeatherClientTest.new
end
