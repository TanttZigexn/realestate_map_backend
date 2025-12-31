class Room < ApplicationRecord
  has_many :room_viewings, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :latitude, presence: true, numericality: { in: -90.0..90.0 }
  validates :longitude, presence: true, numericality: { in: -180.0..180.0 }
  validates :status, inclusion: { in: %w[available rented] }
  validates :room_type, inclusion: { in: %w[room studio apartment] }, allow_nil: true

  # Callbacks
  before_save :set_location_from_coordinates

  # Scopes for filtering
  scope :available, -> { where(status: "available") }
  scope :by_room_type, ->(type) { where(room_type: type) if type.present? }
  scope :price_between, ->(min, max) {
    query = all
    query = query.where("price >= ?", min) if min.present? && min.to_f > 0
    query = query.where("price <= ?", max) if max.present? && max.to_f > 0
    query
  }
  scope :area_between, ->(min, max) {
    query = all
    query = query.where("area >= ?", min) if min.present? && min.to_f > 0
    query = query.where("area <= ?", max) if max.present? && max.to_f > 0
    query
  }

  # PostGIS spatial queries
  scope :within_bounds, ->(north, south, east, west) {
    where(
      "location && ST_MakeEnvelope(?, ?, ?, ?, 4326)",
      west.to_f, south.to_f, east.to_f, north.to_f
    )
  }

  scope :within_radius, ->(lat, lng, radius) {
    where(
      "ST_DWithin(location, ST_MakePoint(?, ?)::geography, ?)",
      lng.to_f, lat.to_f, radius.to_f
    )
  }

  # GeoJSON conversion (Mapbox standard format)
  def to_geojson_feature
    feature = {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [ longitude, latitude ] # GeoJSON: [lng, lat]
      },
      properties: {
        id: id,
        title: title,
        price: price,
        area: area,
        address: address,
        roomType: room_type,
        status: status,
        description: description,
        phone: phone,
        phoneFormatted: phone_formatted
      }
    }

    # Add distance if available (from address search)
    if respond_to?(:distance) && distance.present?
      feature[:properties][:distance] = distance.round(0) # in meters
    end

    feature
  end

  def self.to_geojson_feature_collection(rooms)
    {
      type: "FeatureCollection",
      features: rooms.map(&:to_geojson_feature)
    }
  end

  # Helper methods
  def phone_formatted
    return nil unless phone.present?
    # Format: (024) 1234-5678
    phone.gsub(/(\d{2,4})(\d{4})(\d{4})/, '(\1) \2-\3')
  end

  private

  def set_location_from_coordinates
    if latitude.present? && longitude.present?
      # PostGIS POINT format: POINT(lng lat)
      self.location = "POINT(#{longitude} #{latitude})"
    end
  end
end
