module Api
  module V1
    class RoomsController < ApplicationController
      MAX_RESULTS = 100

      def index
        @rooms = Room.all

        # Apply geographic filters (bounding box OR radius)
        @rooms = apply_geo_filters(@rooms)

        # Apply attribute filters
        @rooms = apply_attribute_filters(@rooms)

        # Limit results for performance
        @rooms = @rooms.limit(MAX_RESULTS)

        # Return GeoJSON FeatureCollection
        render json: Room.to_geojson_feature_collection(@rooms)
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      end

      def show
        @room = Room.find(params[:id])
        render json: @room.to_geojson_feature
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Room not found" }, status: :not_found
      end

      private

      def apply_geo_filters(scope)
        # Bounding box filter (priority over radius)
        if bounding_box_params_present?
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

      def radius_params_present?
        params[:lat].present? && params[:lng].present? && params[:radius].present?
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
