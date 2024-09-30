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
    weather_result = Rails.cache.fetch("GetForecast-#{latitude}-#{longitude}", expires_in: 30.minutes) do
      cache_hit = false
      WEATHER_CLIENT.get_weather_for_coordinates(latitude: latitude, longitude: longitude)
    end
    case weather_result
    when WeatherClient::WeatherResult
      Success(:forecast, **{ weather_result:, cache_hit: })
    else
      # If we can't get the forecast data, we don't want to cache a bad result
      Rails.cache.delete("GetForecast-#{latitude}-#{longitude}")
      Failure(:forecast_failure, **{ weather_result:, cache_hit: })
    end
  end
end
