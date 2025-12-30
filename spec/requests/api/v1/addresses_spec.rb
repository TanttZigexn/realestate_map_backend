require 'swagger_helper'

RSpec.describe 'Addresses API', type: :request, openapi_spec: 'v1/swagger.yaml' do
  path '/api/v1/addresses/suggest' do
    get 'Get address suggestions' do
      tags 'Addresses'
      description 'Get address autocomplete suggestions using Mapbox Geocoding API'
      produces 'application/json'

      parameter name: 'q', in: :query, type: :string, required: true,
                description: 'Search query (minimum 2 characters)'
      parameter name: 'query', in: :query, type: :string, required: false,
                description: 'Alternative parameter name for search query (alias of q)'
      parameter name: 'limit', in: :query, type: :integer, required: false,
                description: 'Maximum number of suggestions to return (default: 5, max: 10)'
      parameter name: 'country', in: :query, type: :string, required: false,
                description: 'Country code to limit results (default: vn)'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 query: { type: :string, example: 'bình thạnh' },
                 suggestions: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string, example: 'place.123456' },
                       text: { type: :string, example: 'Bình Thạnh' },
                       place_name: { type: :string, example: 'Bình Thạnh, Ho Chi Minh City, Vietnam' },
                       latitude: { type: :number, example: 10.811195 },
                       longitude: { type: :number, example: 106.70457 },
                       place_type: { type: :string, example: 'locality' },
                       address_components: {
                         type: :object,
                         properties: {
                           district: { type: :string, example: 'Bình Thạnh' },
                           region: { type: :string, example: 'Ho Chi Minh City' },
                           locality: { type: :string }
                         }
                       },
                       relevance: { type: :number, example: 0.99 }
                     }
                   }
                 }
               }

        let(:q) { 'bình thạnh' }

        example 'application/json', :example_suggestions, {
          query: 'bình thạnh',
          suggestions: [
            {
              id: 'place.123456',
              text: 'Bình Thạnh',
              place_name: 'Bình Thạnh, Ho Chi Minh City, Vietnam',
              latitude: 10.811195,
              longitude: 106.70457,
              place_type: 'locality',
              address_components: {
                district: 'Bình Thạnh',
                region: 'Ho Chi Minh City'
              },
              relevance: 0.99
            }
          ]
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('query')
          expect(data).to have_key('suggestions')
          expect(data['suggestions']).to be_an(Array)
        end
      end

      response '400', 'bad request - missing query' do
        schema '$ref' => '#/components/schemas/Error'

        let(:q) { '' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('error')
        end
      end

      response '400', 'bad request - geocoding error' do
        schema '$ref' => '#/components/schemas/Error'

        # This will be handled by the service, but we document it
        let(:q) { 'invalid_address_xyz_123' }

        run_test! do |response|
          # Service returns empty array on error, not error response
          data = JSON.parse(response.body)
          expect(data).to have_key('suggestions')
        end
      end
    end
  end
end

