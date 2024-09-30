Geocoder.configure(
  lookup: :google,
  api_key: Rails.application.credentials[Rails.env.to_s]["googlemaps_api_key"]
)
