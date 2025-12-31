require 'swagger_helper'

RSpec.describe 'Room Images API', type: :request, openapi_spec: 'v1/swagger.yaml' do
  path '/api/v1/room_images/random' do
    get 'Get random room image' do
      tags 'Room Images'
      description 'Get a random room image URL based on room type (room, studio, apartment)'
      produces 'application/json'

      parameter name: 'type', in: :query, type: :string, required: false,
                description: 'Room type (room, studio, apartment). If not provided, returns random image from all types.',
                schema: {
                  type: :string,
                  enum: ['room', 'studio', 'apartment']
                }

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 image_url: {
                   type: :string,
                   example: 'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png'
                 },
                 type: {
                   type: :string,
                   nullable: true,
                   example: 'room'
                 },
                 timestamp: {
                   type: :string,
                   format: :'date-time',
                   example: '2024-01-15T10:30:00Z'
                 }
               },
               required: ['image_url', 'timestamp']

        let(:type) { 'room' }

        example 'application/json', :example_random_image, {
          image_url: 'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png',
          type: 'room',
          timestamp: '2024-01-15T10:30:00Z'
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('image_url')
          expect(data).to have_key('timestamp')
          expect(data['image_url']).to be_a(String)
          expect(data['image_url']).to start_with('http://')
        end
      end

      response '200', 'successful - no type specified' do
        schema type: :object,
               properties: {
                 image_url: { type: :string },
                 type: { type: :string, nullable: true },
                 timestamp: { type: :string, format: :'date-time' }
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('image_url')
          expect(data['image_url']).to be_a(String)
        end
      end
    end
  end

  path '/api/v1/room_images/list' do
    get 'List all room images by type' do
      tags 'Room Images'
      description 'Get all available room images organized by room type. Useful for debugging or getting all image URLs.'
      produces 'application/json'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 images_by_type: {
                   type: :object,
                   properties: {
                     room: {
                       type: :array,
                       items: { type: :string },
                       example: [
                         'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png'
                       ]
                     },
                     studio: {
                       type: :array,
                       items: { type: :string }
                     },
                     apartment: {
                       type: :array,
                       items: { type: :string }
                     }
                   }
                 }
               },
               required: ['images_by_type']

        example 'application/json', :example_list_images, {
          images_by_type: {
            room: [
              'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png'
            ],
            studio: [],
            apartment: []
          }
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('images_by_type')
          expect(data['images_by_type']).to be_a(Hash)
          expect(data['images_by_type']).to have_key('room')
          expect(data['images_by_type']).to have_key('studio')
          expect(data['images_by_type']).to have_key('apartment')
        end
      end
    end
  end
end

