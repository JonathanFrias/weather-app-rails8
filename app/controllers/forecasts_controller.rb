class ForecastsController < ApplicationController
  def index
  end

  def get_forecast
    address = params[:address]
    coordinates = Geocoder.coordinates(address)

    if coordinates
      latitude, longitude = coordinates
      forecast_data = fetch_forecast(latitude, longitude)

      if forecast_data
        @forecast = parse_forecast(forecast_data)
        @cached = false

        # Cache the forecast data
        Rails.cache.write(cache_key(latitude, longitude), @forecast, expires_in: 30.minutes)
      else
        @error = "Unable to fetch forecast data"
      end
    else
      @error = "Unable to geocode the address"
    end

    render :index
  end

  private

  def fetch_forecast(latitude, longitude)
    cached_forecast = Rails.cache.read(cache_key(latitude, longitude))

    if cached_forecast
      @cached = true
      return cached_forecast
    end

    api_key = Rails.application.credentials.openweathermap_api_key
    url = "http://api.openweathermap.org/data/2.5/weather?lat=#{latitude}&lon=#{longitude}&appid=#{api_key}&units=metric"

    response = HTTPX.get(url)

    if response.status.success?
      response.json
    else
      nil
    end
  end

  def parse_forecast(data)
    {
      temperature: data["main"]["temp"],
      high: data["main"]["temp_max"],
      low: data["main"]["temp_min"],
      description: data["weather"].first["description"]
    }
  end

  def cache_key(latitude, longitude)
    "forecast/#{latitude},#{longitude}"
  end
end
