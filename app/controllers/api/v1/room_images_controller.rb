module Api
  module V1
    class RoomImagesController < ApplicationController
      def random
        room_type = params[:type] || params[:room_type]
        
        image_url = RoomImageService.random_image(room_type)
        
        render json: {
          image_url: image_url,
          room_type: room_type,
          timestamp: Time.current.iso8601
        }
      end
      
      def list
        # Trả về tất cả ảnh theo type (optional, để debug)
        images_by_type = RoomImageService.all_images_by_type
        
        render json: {
          images_by_type: images_by_type.transform_values do |urls|
            # Tất cả đều là full URL, trả về trực tiếp
            urls
          end
        }
      end
    end
  end
end

