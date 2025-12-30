module Api
  module V1
    class RoomsController < ApplicationController
      MAX_RESULTS = 100

      def index
        @rooms = Room.all

        # Apply geographic filters (address > bounding box > radius)
        @rooms = apply_geo_filters(@rooms)

        # Apply attribute filters
        @rooms = apply_attribute_filters(@rooms)

        # Sort by distance if address search was used
        if address_params_present? && @geocoded_lat && @geocoded_lng
          # Use sanitize_sql_array to safely interpolate values
          distance_sql = Room.sanitize_sql_array([
            "rooms.*, ST_Distance(location, ST_MakePoint(?, ?)::geography) as distance",
            @geocoded_lng.to_f, @geocoded_lat.to_f
          ])
          @rooms = @rooms.select(distance_sql).order("distance ASC")
        end

        # Limit results for performance
        @rooms = @rooms.limit(MAX_RESULTS)

        # Return GeoJSON FeatureCollection
        render json: Room.to_geojson_feature_collection(@rooms)
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      rescue GeocodingService::GeocodingError => e
        render json: { error: e.message }, status: :bad_request
      rescue GeocodingService::AddressNotFoundError => e
        render json: { error: "Address not found: #{params[:address]}" }, status: :bad_request
      end

      def show
        @room = Room.find(params[:id])
        render json: @room.to_geojson_feature
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Room not found" }, status: :not_found
      end

      private

      def apply_geo_filters(scope)
        # Address search (highest priority)
        if address_params_present?
          geocode_result = geocode_address
          # Store geocoded coordinates for sorting
          @geocoded_lat = geocode_result[:latitude]
          @geocoded_lng = geocode_result[:longitude]

          radius = params[:address_radius].present? ? params[:address_radius].to_f : 5000.0
          validate_radius_value!(radius)
          scope = scope.within_radius(
            geocode_result[:latitude],
            geocode_result[:longitude],
            radius
          )

          # Filter thêm theo district nếu có để tăng độ chính xác
          if geocode_result[:address_components] && geocode_result[:address_components][:district]
            district_name = geocode_result[:address_components][:district]
            # Normalize district name để match với database
            scope = scope.where(
              "address ILIKE ? OR address ILIKE ?",
              "%#{district_name}%",
              "%Quận #{district_name}%"
            )
          end
        # Bounding box filter
        elsif bounding_box_params_present?
          validate_bounding_box_params!
          scope = scope.within_bounds(
            params[:north].to_f,
            params[:south].to_f,
            params[:east].to_f,
            params[:west].to_f
          )
        # Radius filter
        elsif radius_params_present?
          validate_radius_params!
          scope = scope.within_radius(
            params[:lat].to_f,
            params[:lng].to_f,
            params[:radius].to_f
          )
        end

        scope
      end

      def apply_attribute_filters(scope)
        # Price filter
        scope = scope.price_between(
          params[:min_price],
          params[:max_price]
        )

        # Area filter
        scope = scope.area_between(
          params[:min_area],
          params[:max_area]
        )

        # Room type filter
        scope = scope.by_room_type(params[:room_type])

        # Status filter (default to available if not specified)
        scope = scope.where(status: params[:status]) if params[:status].present?

        scope
      end

      def bounding_box_params_present?
        params[:north].present? && params[:south].present? &&
        params[:east].present? && params[:west].present?
      end

      def address_params_present?
        params[:address].present?
      end

      def radius_params_present?
        params[:lat].present? && params[:lng].present? && params[:radius].present?
      end

      def geocode_address
        country = params[:country] || "vn"
        result = GeocodingService.geocode(params[:address], country: country)

        raise GeocodingService::AddressNotFoundError, "Address not found" if result.nil?

        result
      end

      def validate_radius_value!(radius)
        raise ArgumentError, "Invalid radius: must be positive" if radius <= 0
        raise ArgumentError, "Radius too large: max 50000 meters" if radius > 50000
      end

      def validate_bounding_box_params!
        north = params[:north].to_f
        south = params[:south].to_f
        east = params[:east].to_f
        west = params[:west].to_f

        raise ArgumentError, "Invalid bounding box: north must be > south" if north <= south
        raise ArgumentError, "Invalid bounding box: east must be > west" if east <= west
        raise ArgumentError, "Invalid latitude: must be between -90 and 90" if north.abs > 90 || south.abs > 90
        raise ArgumentError, "Invalid longitude: must be between -180 and 180" if east.abs > 180 || west.abs > 180
      end

      def validate_radius_params!
        lat = params[:lat].to_f
        lng = params[:lng].to_f
        radius = params[:radius].to_f

        raise ArgumentError, "Invalid latitude: must be between -90 and 90" if lat.abs > 90
        raise ArgumentError, "Invalid longitude: must be between -180 and 180" if lng.abs > 180
        raise ArgumentError, "Invalid radius: must be positive" if radius <= 0
        raise ArgumentError, "Radius too large: max 50000 meters" if radius > 50000
      end
    end
  end
end
