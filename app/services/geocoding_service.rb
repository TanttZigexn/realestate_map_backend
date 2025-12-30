require "net/http"
require "uri"
require "json"
require "digest"

class GeocodingService
  MAPBOX_BASE_URL = "https://api.mapbox.com/geocoding/v5/mapbox.places"
  CACHE_TTL = 30.days

  class GeocodingError < StandardError; end
  class AddressNotFoundError < GeocodingError; end

  def self.geocode(address, country: "vn")
    new.geocode(address, country: country)
  end

  def geocode(address, country: "vn")
    return nil if address.blank?

    # Check cache first
    cache_key = cache_key_for(address, country)
    cached_result = Rails.cache.read(cache_key)
    return cached_result if cached_result.present?

    # Geocode via Mapbox API
    result = fetch_from_mapbox(address, country)

    # Cache the result
    Rails.cache.write(cache_key, result, expires_in: CACHE_TTL)

    result
  rescue AddressNotFoundError => e
    # Cache negative results for shorter time to avoid repeated API calls
    Rails.cache.write(cache_key, { error: e.message }, expires_in: 1.hour)
    raise e
  end

  private

  def fetch_from_mapbox(address, country)
    access_token = ENV.fetch("MAPBOX_ACCESS_TOKEN") do
      raise GeocodingError, "MAPBOX_ACCESS_TOKEN environment variable is not set"
    end

    encoded_address = URI.encode_www_form_component(address)
    url = "#{MAPBOX_BASE_URL}/#{encoded_address}.json"
    params = {
      access_token: access_token,
      country: country,
      limit: 1
    }

    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    case response.code.to_i
    when 200
      data = JSON.parse(response.body)
      parse_mapbox_response(data)
    when 401
      raise GeocodingError, "Invalid Mapbox access token"
    when 429
      raise GeocodingError, "Mapbox API rate limit exceeded"
    else
      raise GeocodingError, "Mapbox API error: #{response.code}"
    end
  rescue JSON::ParserError => e
    raise GeocodingError, "Failed to parse Mapbox response: #{e.message}"
  rescue Timeout::Error, Net::ReadTimeout, Net::OpenTimeout => e
    raise GeocodingError, "Mapbox API timeout: #{e.message}"
  rescue StandardError => e
    raise GeocodingError, "Geocoding failed: #{e.message}"
  end

  def parse_mapbox_response(data)
    features = data["features"]
    if features.blank? || features.empty?
      raise AddressNotFoundError, "No results found for this address"
    end

    # Get the first (most relevant) result
    feature = features.first
    coordinates = feature["center"] # Mapbox returns [lng, lat]

    {
      latitude: coordinates[1],
      longitude: coordinates[0],
      formatted_address: feature.dig("place_name"),
      place_type: feature.dig("place_type", 0)
    }
  end

  def cache_key_for(address, country)
    normalized_address = address.to_s.strip.downcase
    "geocode:#{Digest::MD5.hexdigest("#{normalized_address}:#{country}")}"
  end
end
