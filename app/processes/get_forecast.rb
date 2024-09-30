class GetForecast < Solid::Process
  input do
    attribute :address
  end

  def call(attributes)
    Given(attributes)
      .and_then(:get_coordinates)
      .and_then(:fetch_forecast)
  end

  def get_coordinates(address:)
    # No expires_in: here because coordinates don't change
    # Solid cache support means we can have long-lived cache entries
    coordinates = Rails.cache.fetch("GetCoordinates-#{address}") { Geocoder.coordinates(address) }

    if coordinates
      latitude, longitude = coordinates
      Continue(latitude:, longitude:)
    else
      # If we can't geocode the address, we don't want to cache a bad result
      Rails.cache.delete("GetCoordinates-#{address}")
      Failure(:geocode_failure, **{ message: "Unable to find the address #{address} " })
    end
  end

  def fetch_forecast(address:, latitude:, longitude:)
    cache_hit = true

    forecast_data = Rails.cache.fetch("GetForecast-#{latitude}-#{longitude}", expires_in: 30.minutes) do
      cache_hit = false
      api_key = Rails.application.credentials.openweathermap_api_key
      # API Docs: https://openweathermap.org/current
      url = "http://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&appid=#{api_key}&units=imperial"

      # HTTPX is awesome: Why you should use it: https://honeyryderchuck.gitlab.io/2023/10/15/state-of-ruby-http-clients-use-httpx.html
      response = HTTPX.get(url)
      response.json if response.status == 200
    end

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
      Success(:forecast, **{
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
        city_name: city_name,
        cache_hit: cache_hit
      })
    in _
      # If we can't get the forecast data, we don't want to cache a bad result
      Rails.cache.delete("GetForecast-#{latitude}-#{longitude}")
      Failure(:forecast_failure, **{ forecast_data: })
    end
  end
end
