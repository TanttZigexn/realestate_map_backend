module Api
  module V1
    class RoomViewingsController < ApplicationController
      before_action :set_room_viewing, only: [:show, :update]

      MAX_PER_PAGE = 100
      DEFAULT_PER_PAGE = 20

      def index
        @room_viewings = RoomViewing.all
        @room_viewings = apply_filters(@room_viewings)
        @room_viewings = @room_viewings.order(created_at: :desc)

        per_page = [params[:per_page]&.to_i || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
        @room_viewings = @room_viewings.page(params[:page] || 1).per(per_page)

        render json: {
          data: @room_viewings.map { |viewing| format_room_viewing(viewing) },
          meta: {
            current_page: @room_viewings.current_page,
            per_page: per_page,
            total_pages: @room_viewings.total_pages,
            total_count: @room_viewings.total_count
          }
        }
      end

      def show
        render json: format_room_viewing(@room_viewing, include_room: true)
      end

      def create
        @room_viewing = RoomViewing.new(room_viewing_params)

        if @room_viewing.save
          render json: format_room_viewing(@room_viewing), status: :created
        else
          render json: { errors: @room_viewing.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @room_viewing.update(update_params)
          render json: format_room_viewing(@room_viewing)
        else
          render json: { errors: @room_viewing.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_room_viewing
        @room_viewing = RoomViewing.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Room viewing not found' }, status: :not_found
      end

      def apply_filters(scope)
        scope = scope.by_room(params[:room_id]) if params[:room_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope
      end

      def room_viewing_params
        params.require(:room_viewing).permit(
          :room_id, :name, :email, :phone, :preferred_date, :message
        )
      end

      def update_params
        params.require(:room_viewing).permit(:status)
      end

      def format_room_viewing(viewing, include_room: false)
        result = {
          id: viewing.id,
          room_id: viewing.room_id,
          name: viewing.name,
          email: viewing.email,
          phone: viewing.phone,
          preferred_date: viewing.preferred_date.iso8601,
          message: viewing.message,
          status: viewing.status,
          created_at: viewing.created_at.iso8601,
          updated_at: viewing.updated_at.iso8601
        }

        if include_room
          result[:room] = {
            id: viewing.room.id,
            title: viewing.room.title,
            address: viewing.room.address,
            price: viewing.room.price
          }
        end

        result
      end
    end
  end
end

