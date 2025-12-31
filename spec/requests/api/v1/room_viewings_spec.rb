require 'swagger_helper'

RSpec.describe 'Room Viewings API', type: :request, openapi_spec: 'v1/swagger.yaml' do
  path '/api/v1/room_viewings' do
    post 'Create room viewing appointment' do
      tags 'Room Viewings'
      description 'Create a new room viewing appointment'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :room_viewing, in: :body, schema: {
        type: :object,
        properties: {
          room_id: { type: :integer, example: 1 },
          name: { type: :string, example: 'Nguyễn Văn A' },
          email: { type: :string, example: 'nguyenvana@example.com' },
          phone: { type: :string, example: '0901234567' },
          preferred_date: { type: :string, format: :'date-time', example: '2026-02-15T14:00:00Z' },
          message: { type: :string, example: 'Tôi muốn xem phòng vào buổi chiều' }
        },
        required: ['room_id', 'name', 'email', 'phone', 'preferred_date']
      }

      response '201', 'room viewing created' do
        schema type: :object,
               properties: {
                 id: { type: :integer, example: 1 },
                 room_id: { type: :integer, example: 1 },
                 name: { type: :string, example: 'Nguyễn Văn A' },
                 email: { type: :string, example: 'nguyenvana@example.com' },
                 phone: { type: :string, example: '0901234567' },
                 preferred_date: { type: :string, format: :'date-time', example: '2026-02-15T14:00:00Z' },
                 message: { type: :string, example: 'Tôi muốn xem phòng vào buổi chiều' },
                 status: { type: :string, example: 'pending' },
                 created_at: { type: :string, format: :'date-time' },
                 updated_at: { type: :string, format: :'date-time' }
               },
               required: ['id', 'room_id', 'name', 'email', 'phone', 'preferred_date', 'status']

        let(:room) { Room.first || Room.create!(title: 'Test Room', price: 5000000, latitude: 21.0285, longitude: 105.8542, status: 'available') }
        let(:room_viewing) do
          {
            room_id: room.id,
            name: 'Nguyễn Văn A',
            email: 'nguyenvana@example.com',
            phone: '0901234567',
            preferred_date: 1.month.from_now.iso8601,
            message: 'Tôi muốn xem phòng vào buổi chiều'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('status')
          expect(data['status']).to eq('pending')
        end
      end

      response '422', 'validation error' do
        schema type: :object,
               properties: {
                 errors: {
                   type: :object,
                   additionalProperties: {
                     type: :array,
                     items: { type: :string }
                   }
                 }
               }

        let(:room_viewing) { { room_id: nil, name: '', email: 'invalid' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('errors')
        end
      end
    end

    get 'List room viewings' do
      tags 'Room Viewings'
      description 'Get a list of room viewing appointments with optional filters'
      produces 'application/json'

      parameter name: 'room_id', in: :query, type: :integer, required: false,
                description: 'Filter by room ID'
      parameter name: 'status', in: :query, type: :string, required: false,
                description: 'Filter by status',
                schema: {
                  type: :string,
                  enum: ['pending', 'confirmed', 'cancelled', 'completed']
                }
      parameter name: 'page', in: :query, type: :integer, required: false,
                description: 'Page number (default: 1)'
      parameter name: 'per_page', in: :query, type: :integer, required: false,
                description: 'Items per page (default: 20, max: 100)'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       room_id: { type: :integer },
                       name: { type: :string },
                       email: { type: :string },
                       phone: { type: :string },
                       preferred_date: { type: :string, format: :'date-time' },
                       message: { type: :string, nullable: true },
                       status: { type: :string },
                       created_at: { type: :string, format: :'date-time' },
                       updated_at: { type: :string, format: :'date-time' }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     current_page: { type: :integer },
                     per_page: { type: :integer },
                     total_pages: { type: :integer },
                     total_count: { type: :integer }
                   }
                 }
               },
               required: ['data', 'meta']

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('data')
          expect(data).to have_key('meta')
          expect(data['data']).to be_an(Array)
        end
      end
    end
  end

  path '/api/v1/room_viewings/{id}' do
    get 'Show room viewing' do
      tags 'Room Viewings'
      description 'Get details of a specific room viewing appointment'
      produces 'application/json'

      parameter name: 'id', in: :path, type: :integer, required: true,
                description: 'Room viewing ID'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 room_id: { type: :integer },
                 room: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     title: { type: :string },
                     address: { type: :string, nullable: true },
                     price: { type: :integer }
                   }
                 },
                 name: { type: :string },
                 email: { type: :string },
                 phone: { type: :string },
                 preferred_date: { type: :string, format: :'date-time' },
                 message: { type: :string, nullable: true },
                 status: { type: :string },
                 created_at: { type: :string, format: :'date-time' },
                 updated_at: { type: :string, format: :'date-time' }
               },
               required: ['id', 'room_id', 'name', 'email', 'phone', 'preferred_date', 'status']

        let(:room) { Room.first || Room.create!(title: 'Test Room', price: 5000000, latitude: 21.0285, longitude: 105.8542, status: 'available') }
        let(:id) { RoomViewing.create!(room: room, name: 'Test User', email: 'test@example.com', phone: '0901234567', preferred_date: 1.month.from_now).id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('room')
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

    patch 'Update room viewing status' do
      tags 'Room Viewings'
      description 'Update the status of a room viewing appointment'
      consumes 'application/json'
      produces 'application/json'

      parameter name: 'id', in: :path, type: :integer, required: true,
                description: 'Room viewing ID'
      parameter name: :room_viewing, in: :body, schema: {
        type: :object,
        properties: {
          status: {
            type: :string,
            enum: ['pending', 'confirmed', 'cancelled', 'completed'],
            example: 'confirmed'
          }
        },
        required: ['status']
      }

      response '200', 'room viewing updated' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 status: { type: :string },
                 updated_at: { type: :string, format: :'date-time' }
               },
               required: ['id', 'status']

        let(:room) { Room.first || Room.create!(title: 'Test Room', price: 5000000, latitude: 21.0285, longitude: 105.8542, status: 'available') }
        let(:room_viewing_record) { RoomViewing.create!(room: room, name: 'Test User', email: 'test@example.com', phone: '0901234567', preferred_date: 1.month.from_now) }
        let(:id) { room_viewing_record.id }
        let(:room_viewing) { { status: 'confirmed' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('status')
          expect(data['status']).to eq('confirmed')
        end
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 99999 }
        let(:room_viewing) { { status: 'confirmed' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('error')
        end
      end

      response '422', 'validation error' do
        schema type: :object,
               properties: {
                 errors: {
                   type: :object,
                   additionalProperties: {
                     type: :array,
                     items: { type: :string }
                   }
                 }
               }

        let(:room) { Room.first || Room.create!(title: 'Test Room', price: 5000000, latitude: 21.0285, longitude: 105.8542, status: 'available') }
        let(:room_viewing_record) { RoomViewing.create!(room: room, name: 'Test User', email: 'test@example.com', phone: '0901234567', preferred_date: 1.month.from_now) }
        let(:id) { room_viewing_record.id }
        let(:room_viewing) { { status: 'invalid_status' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('errors')
        end
      end
    end
  end
end

