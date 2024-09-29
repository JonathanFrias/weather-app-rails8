class Forecast::GetForecast < Solid::Process
  def initialize(location)
    @location = location
  end

  def call
    # Get the forecast from the API
  end
end
