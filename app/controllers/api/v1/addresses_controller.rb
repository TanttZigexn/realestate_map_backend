module Api
  module V1
    class AddressesController < ApplicationController
      def suggest
        query = params[:q] || params[:query]
        
        if query.blank?
          return render json: { error: "Query parameter 'q' or 'query' is required" }, status: :bad_request
        end

        limit = params[:limit]&.to_i || 5
        limit = [limit, 10].min  # Max 10 suggestions
        country = params[:country] || "vn"

        suggestions = GeocodingService.autocomplete(query, country: country, limit: limit)

        render json: {
          query: query,
          suggestions: suggestions
        }
      rescue GeocodingService::GeocodingError => e
        render json: { error: e.message }, status: :bad_request
      end
    end
  end
end

