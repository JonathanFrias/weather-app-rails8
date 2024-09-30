class WeatherClient
  def initialize(api_key:)
    @api_key = api_key
  end

  def get_weather_for_coordinates(latitude:, longitude:)
    # API Docs: https://openweathermap.org/current
    url = "http://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&appid=#{@api_key}&units=imperial"

    # HTTPX is awesome: Why you should use it: https://honeyryderchuck.gitlab.io/2023/10/15/state-of-ruby-http-clients-use-httpx.html
    response = HTTPX.get(url)
    forecast_data = response.json

    case forecast_data&.deep_symbolize_keys
    # Use Ruby's awesome pattern matching to elegantly destructure the response
    in {
      coord: { lon: longitude, lat: latitude },
      # They may have a lot of weather data from nearby stations, but we only support the first one for now
      weather: [{ main: weather_main, description: weather_description }, *_rest],
      main: {
        temp: temperature,
        feels_like: feels_like,
        temp_min: temp_min,
        temp_max: temp_max,
        humidity: humidity
      },
      wind: { speed: wind_speed },
      name: city_name
    }
    then
      WeatherResult.new(
        longitude: longitude,
        latitude: latitude,
        weather_main: weather_main,
        weather_description: weather_description,
        temperature: temperature,
        feels_like: feels_like,
        temp_min: temp_min,
        temp_max: temp_max,
        humidity: humidity,
        wind_speed: wind_speed,
        city_name: city_name
      )
    else
      nil
    end
  end

  class WeatherResult
    attr_reader :longitude, :latitude, :weather_main, :weather_description, :temperature, :feels_like, :temp_min, :temp_max, :humidity, :wind_speed, :city_name

    def initialize(longitude:, latitude:, weather_main:, weather_description:, temperature:, feels_like:, temp_min:, temp_max:, humidity:, wind_speed:, city_name:)
      @longitude = longitude
      @latitude = latitude
      @weather_main = weather_main
      @weather_description = weather_description
      @temperature = temperature
      @feels_like = feels_like
      @temp_min = temp_min
      @temp_max = temp_max
      @humidity = humidity
      @wind_speed = wind_speed
      @city_name = city_name
    end

    def as_json
      {
        longitude: longitude,
        latitude: latitude,
        weather_main: weather_main,
        weather_description: weather_description,
        temperature: temperature,
        feels_like: feels_like,
        temp_min: temp_min,
        temp_max: temp_max,
        humidity: humidity,
        wind_speed: wind_speed,
        city_name: city_name
      }
    end
  end
end

