module Api
  module V1
    class RoomImagesController < ApplicationController
      def random
        type = params[:type]
        
        image_url = RoomImageService.random_image(type)
        
        render json: {
          image_url: image_url,
          type: type,
          timestamp: Time.current.iso8601
        }
      end
      
      def list
        images_by_type = RoomImageService.all_images_by_type
        
        render json: {
          images_by_type: images_by_type.transform_values do |urls|
            urls
          end
        }
      end
    end
  end
end

