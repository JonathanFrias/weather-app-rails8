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
    result = GetForecast.new.fetch_forecast(address: nil, latitude: 37.7749, longitude: -122.4194)
    case result
    when Solid::Success
      expect(result.value[:weather_result]).to be_present
    else
      fail "Expected forecast data"
    end
  end
end
