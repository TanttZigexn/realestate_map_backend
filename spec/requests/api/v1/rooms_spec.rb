require 'swagger_helper'

RSpec.describe 'Rooms API', type: :request, openapi_spec: 'v1/swagger.yaml' do
  path '/api/v1/rooms' do
    get 'List rooms' do
      tags 'Rooms'
      description 'Get a list of rental rooms with optional geographic and attribute filters'
      produces 'application/json'

      parameter name: 'address', in: :query, type: :string, required: false,
                description: 'Address to search around (e.g., "Quận Đống Đa, Hà Nội")'
      parameter name: 'address_radius', in: :query, type: :integer, required: false,
                description: 'Search radius in meters when using address (default: 5000, max: 50000)'
      parameter name: 'north', in: :query, type: :number, required: false,
                description: 'Northern latitude for bounding box search'
      parameter name: 'south', in: :query, type: :number, required: false,
                description: 'Southern latitude for bounding box search'
      parameter name: 'east', in: :query, type: :number, required: false,
                description: 'Eastern longitude for bounding box search'
      parameter name: 'west', in: :query, type: :number, required: false,
                description: 'Western longitude for bounding box search'
      parameter name: 'lat', in: :query, type: :number, required: false,
                description: 'Latitude for radius search'
      parameter name: 'lng', in: :query, type: :number, required: false,
                description: 'Longitude for radius search'
      parameter name: 'radius', in: :query, type: :integer, required: false,
                description: 'Radius in meters for radius search (max: 50000)'
      parameter name: 'min_price', in: :query, type: :integer, required: false,
                description: 'Minimum price filter'
      parameter name: 'max_price', in: :query, type: :integer, required: false,
                description: 'Maximum price filter'
      parameter name: 'min_area', in: :query, type: :number, required: false,
                description: 'Minimum area filter (m²)'
      parameter name: 'max_area', in: :query, type: :number, required: false,
                description: 'Maximum area filter (m²)'
      parameter name: 'room_type', in: :query, type: :string, required: false,
                enum: [ 'room', 'studio', 'apartment' ],
                description: 'Filter by room type'
      parameter name: 'status', in: :query, type: :string, required: false,
                enum: [ 'available', 'rented' ],
                description: 'Filter by status'

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/GeoJSONFeatureCollection'

        let(:room) { Room.create!(title: 'Test Room', price: 2000000, latitude: 21.0285, longitude: 105.8542, status: 'available') }

        example 'application/json', :example_without_filters, {
          type: 'FeatureCollection',
          features: [
            {
              type: 'Feature',
              geometry: {
                type: 'Point',
                coordinates: [ 105.8542, 21.0285 ]
              },
              properties: {
                id: 1,
                title: 'Studio cozy gần Hồ Tây',
                price: 3500000,
                area: 25.0,
                address: '100 Đường ABC, Quận Đống Đa, Hà Nội',
                roomType: 'studio',
                status: 'available',
                description: 'Phòng studio tại...',
                phone: '02438345678',
                phoneFormatted: '(024) 3834-5678'
              }
            }
          ]
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['type']).to eq('FeatureCollection')
          expect(data['features']).to be_an(Array)
        end
      end

      response '400', 'bad request' do
        schema '$ref' => '#/components/schemas/Error'

        let(:address) { 'InvalidAddressXYZ123' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('error')
        end
      end
    end
  end

  path '/api/v1/rooms/{id}' do
    get 'Show room' do
      tags 'Rooms'
      description 'Get details of a specific room'
      produces 'application/json'

      parameter name: 'id', in: :path, type: :integer, required: true,
                description: 'Room ID'

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/GeoJSONFeature'

        let(:id) { Room.create!(title: 'Test Room', price: 2000000, latitude: 21.0285, longitude: 105.8542, status: 'available').id }

        example 'application/json', :example_room, {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [ 105.8542, 21.0285 ]
          },
          properties: {
            id: 1,
            title: 'Studio cozy gần Hồ Tây',
            price: 3500000,
            area: 25.0,
            address: '100 Đường ABC, Quận Đống Đa, Hà Nội',
            roomType: 'studio',
            status: 'available',
            description: 'Phòng studio tại...',
            phone: '02438345678',
            phoneFormatted: '(024) 3834-5678'
          }
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['type']).to eq('Feature')
          expect(data['properties']['id']).to eq(id)
        end
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('error')
        end
      end
    end
  end
end
