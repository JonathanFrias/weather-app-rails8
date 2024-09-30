# Weather Forecast App on Rails

100% written with Neovim and HI (Human Intelligence), NOT AI

# Table of Contents
4. [Approach](#approach)
3. [Solid Process](#third-example)
1. [Controller](#example)
2. [Weather Client](#example2)
4. [Caching Strategy](#fourth-examplehttpwwwfourthexamplecom)
5. [Turbo Frames](#asdf)
6. [ActiveRecord](#)

## Approach

This application uses a cache system to fetch the current weather for any address input given. If it is not able to find the weather it will report an error to the user.

## Solid Process

I decided to go with service objects, but to avoid the composition problem that most naïve implemenations of service objects usually have, I have used the `solid-process` gem. This allows you to write more scalable business logic, and usings a [railway oriented](https://fsharpforfunandprofit.com/posts/recipe-part2/) approach to error handling. This gem simplifies and provides a context to naturally consume inputs


## Controller

This application has one controller, and doesn't stray too far from the normal rails pattern. The major difference is that I can use ruby's pattern matching to handle more types of errors easily 

```ruby
weather_result = nil
cache_hit = nil
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
```

## Weather Client

As the prompt did not specific a weather source, I have decided to use the api from 
[openweathermap](https://openweathermap.org/). A few things that I like to consider when doing any third party integration is to provide an easy path to swap out integrations, so I decided to wrap the client and result objects in application code. Ruby doesn't have interfaces, but we can still the same style of architecture to be able to swap out different third party api sources.

```ruby
class WeatherClient
  def initialize(api_key); @api_key = api_key; end
  
  def get_weather_from_coordinates(latitude:, longitude:)
    # Openweathermap specific implementation
  end
  
  class WeatherResult
    # snipped for brevity
  end
end
```

As a result of this approach, I can easily define a openweathermap implementation, as well as an implementation for tests.

```ruby
class WeatherClientTest
  def initialize(api_key:) = nil # api key ignored
  
  def get_weather_from_coordinates(latitude:, longitude:)
    # returns synthetic WeatherClient::WeatherClientResult object
  end
end
```

Since this app is primarily concerned with getting weather data, the concept of working with this interface should be a first class concern. I wanted to avoid all the constant high complexity cost and ceremony that's involved with an patterns like dependency injection, IOC container, etc in an effort to avoid treating the integration like a second class citizen in the app. So it should be a concern on the same level as the database connection.


```ruby
# config/initializers/weather_client.rb
if Rails.env.production?
  WEATHER_CLIENT = WeatherClient.new(api_key: Rails.application.credentials[:openweathermap_api_key]).freeze
else
  require "weather_client_test"
  WEATHER_CLIENT = WeatherClientTest.new(api_key: nil).freeze
end
```

This constant removes the need to pay a refactoring tax in order to run tests, and because it is wrapped in a interface/duck typed set of application classes, removes the cohesion problem that globals usually have. It's actually the same approach like provides global access to the database connection via `ActiveRecord::Base.connection`, or the Sequel gem's `DB = Sequel.connect()` pattern. They define an duck typed interface, and you can swap out entire database implementations, without having to pay a tax on every production class in order to handle a dependency injection approach. I've contributed code to the Sequel gem by the way.



## Caching Strategy

So I've opted to use the fantastic `solid_cache` gem to handle caching. This application has 2 layers of caching to find the current forecast. 

1. The first one is the address to coordinates layer. This cache does not have an expiry date because that coordinate location data does not become stale over time.
2. The second cache layer is for the weather that changes constantly. This is pretty simple since I'm using Rails' built in cache helpers

```ruby
cache_hit = true
Rails.cache.fetch("#{latitude}-#{longitude}", expires_in: 30.minutes do
  cache_hit = false
  WEATHER_CLIENT. get_weather_from_coordinates(latitude:, longitude) # Returns WeatherClient::WeatherResult
end
```

## Turbo Frame

After obtaining the relevant `WeatherResult`, that data updates the front end via turbo. It updates the page with the current location data, as well as whether or not the cache was hit using the `cache_hit` pattern above.

