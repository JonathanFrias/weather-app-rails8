require 'rails_helper'

RSpec.describe GetForecast do
  subject { described_class }

  it "can lookup coordinates" do
    result = GetForecast.new.get_coordinates(address: "Jacksonville Beach")
    case result
    in [_, { latitude:, longitude: }]
      expect(latitude).not_to be_blank
      expect(longitude).not_to be_blank
    else
      fail "Could not lookup coordinates!"
    end
  end

  it "can fetch forecast data" do
    result = GetForecast.new.fetch_forecast(37.7749, -122.4194)
    case result
    when Solid::Success
      expect(result.value.keys).to include(:longitude, :latitude, :weather_main, :weather_description, :temperature, :feels_like, :temp_min, :temp_max, :humidity, :wind_speed, :city_name, :cache_hit)
    else
      fail "Expected forecast data"
    end
  end
end
