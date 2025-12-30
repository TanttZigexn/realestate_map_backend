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

  def self.reverse_geocode(latitude, longitude, country: "vn")
    new.reverse_geocode(latitude, longitude, country: country)
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

  public

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
      place_type: feature.dig("place_type", 0),
      address_components: extract_address_components(feature)
    }
  end

  def reverse_geocode(latitude, longitude, country: "vn")
    return nil if latitude.blank? || longitude.blank?

    # Check cache first
    cache_key = reverse_cache_key_for(latitude, longitude, country)
    cached_result = Rails.cache.read(cache_key)
    return cached_result if cached_result.present?

    # Reverse geocode via Mapbox API
    result = fetch_reverse_from_mapbox(latitude, longitude, country)

    # Cache the result
    Rails.cache.write(cache_key, result, expires_in: CACHE_TTL) if result.present?

    result
  rescue AddressNotFoundError => e
    # Cache negative results for shorter time
    Rails.cache.write(cache_key, nil, expires_in: 1.hour)
    raise e
  end

  private

  def fetch_reverse_from_mapbox(latitude, longitude, country)
    access_token = ENV.fetch("MAPBOX_ACCESS_TOKEN") do
      raise GeocodingError, "MAPBOX_ACCESS_TOKEN environment variable is not set"
    end

    url = "#{MAPBOX_BASE_URL}/#{longitude},#{latitude}.json"
    params = {
      access_token: access_token,
      country: country,
      limit: 1,
      types: "address,poi" # Prioritize addresses and points of interest
    }

    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    case response.code.to_i
    when 200
      data = JSON.parse(response.body)
      parse_reverse_mapbox_response(data)
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
    raise GeocodingError, "Reverse geocoding failed: #{e.message}"
  end

  private

  def parse_reverse_mapbox_response(data)
    features = data["features"]
    if features.blank? || features.empty?
      raise AddressNotFoundError, "No results found for these coordinates"
    end

    # Get the first (most relevant) result
    feature = features.first

    {
      formatted_address: feature.dig("place_name"),
      address_components: extract_address_components(feature),
      place_type: feature.dig("place_type", 0)
    }
  end

  def extract_address_components(feature)
    context = feature["context"] || []
    components = {}

    context.each do |ctx|
      id = ctx["id"]
      text = ctx["text"]

      if id.include?("district")
        components[:district] = text
      elsif id.include?("region")
        components[:region] = text
      elsif id.include?("locality")
        components[:locality] = text
      elsif id.include?("neighborhood")
        components[:neighborhood] = text
      end
    end

    # Fallback: Extract district from formatted_address if not in context
    # Example: "Bình Thạnh, Ho Chi Minh City, Vietnam" -> "Bình Thạnh"
    if components[:district].blank? && feature["place_type"]&.first == "locality"
      place_name = feature.dig("place_name") || feature.dig("text", "")
      # Extract first part before comma (usually district name)
      district_match = place_name.match(/^([^,]+)/)
      components[:district] = district_match[1].strip if district_match
    end

    components
  end

  def reverse_cache_key_for(latitude, longitude, country)
    # Round to 4 decimal places (~11 meters precision) for caching
    rounded_lat = latitude.to_f.round(4)
    rounded_lng = longitude.to_f.round(4)
    "reverse_geocode:#{Digest::MD5.hexdigest("#{rounded_lat}:#{rounded_lng}:#{country}")}"
  end

  def cache_key_for(address, country)
    normalized_address = address.to_s.strip.downcase
    "geocode:#{Digest::MD5.hexdigest("#{normalized_address}:#{country}")}"
  end
end
