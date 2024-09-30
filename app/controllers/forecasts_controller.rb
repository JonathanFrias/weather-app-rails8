class ForecastsController < ApplicationController
  def create
    weather_result = nil
    cache_hit = false
    case GetForecast.call(address: params[:address])
    in [:forecast, { weather_result:, cache_hit: } ]
    in [:geocode_failure, { message: }]
      flash.now[:alert] = message
    in [:forecast_failure, { **_data } ]
      # We should have some error reporting here
      # Something like:
      # Rollbar.error("Could not fetch forecast data for #{params[:address]}")
      flash.now[:alert] = "Could not fetch forecast data. Please try again later."
    end

    # Use Turbo Streams to update the page
    render turbo_stream: [
      turbo_stream.replace(:weather_results, partial: "weather_results", locals: { weather_result:, cache_hit: }),
      turbo_stream.replace(:flash, partial: "shared/flash")
    ]
  end
end
