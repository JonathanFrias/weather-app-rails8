class ForecastsController < ApplicationController
  def create
    case GetForecast.call(address: params[:address])
    in [:forecast, { **forecast_data } ]
      @forecast_data = forecast_data
    in [:geocode_failure, { message: }]
      flash.now[:alert] = message
    in [:forecast_failure, { forecast_data: }]
      # We could potentially show what was fetched here even though it failed
      flash.now[:alert] = "Could not fetch forecast data. Please try again later."
    in _
      # We should have some error reporting here
      # Something like:
      # Rollbar.error("Could not fetch forecast data for #{params[:address]}")
      flash.now[:alert] = "Could not fetch forecast data. Please try again later."
    end

    # Use Turbo Streams to update the page
    render turbo_stream: [
      turbo_stream.replace(:weather_results, partial: "weather_results", locals: { forecast_data: @forecast_data }),
      turbo_stream.replace(:flash, partial: "shared/flash")
    ]
  end
end
