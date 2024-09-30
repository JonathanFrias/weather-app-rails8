class WeatherClientTest
  def initialize
  end

  def get_weather_for_coordinates(latitude:, longitude:)
    case [latitude, longitude]
    when [37.7749, -122.4194]
      WeatherClient::WeatherResult.new(
        longitude: -81.3961338,
        latitude: 30.2841224,
        weather_main: "Clouds",
        weather_description: "broken clouds",
        temperature: 70.0,
        feels_like: 70.0,
        temp_min: 70.0,
        temp_max: 70.0,
        humidity: 70,
        wind_speed: 10.0,
        city_name: "Jacksonville Beach"
      )
    else
      nil
    end
  end
end
