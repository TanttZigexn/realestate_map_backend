# Room Viewing Appointment Feature Design

## 1. Overview

Tính năng đặt lịch xem phòng cho phép người dùng đăng ký xem phòng trọ với các thông tin liên hệ và thời gian mong muốn.

## 2. Database Schema

### 2.1. Table: `room_viewings`

```ruby
create_table :room_viewings do |t|
  t.references :room, null: false, foreign_key: true
  t.string :name, null: false
  t.string :email, null: false
  t.string :phone, null: false
  t.datetime :preferred_date, null: false
  t.text :message
  t.string :status, default: 'pending' # pending, confirmed, cancelled, completed
  t.timestamps
end

add_index :room_viewings, :room_id
add_index :room_viewings, :email
add_index :room_viewings, :status
add_index :room_viewings, :preferred_date
```

**Fields:**
- `room_id` (bigint, FK): Reference to rooms table
- `name` (string): Tên người đặt lịch
- `email` (string): Email người đặt lịch
- `phone` (string): Số điện thoại
- `preferred_date` (datetime): Ngày giờ muốn xem phòng
- `message` (text, optional): Tin nhắn thêm từ người dùng
- `status` (string): Trạng thái đặt lịch
  - `pending`: Đang chờ xác nhận (default)
  - `confirmed`: Đã xác nhận
  - `cancelled`: Đã hủy
  - `completed`: Đã hoàn thành
- `created_at`, `updated_at` (timestamps)

## 3. Model

### 3.1. `app/models/room_viewing.rb`

```ruby
class RoomViewing < ApplicationRecord
  belongs_to :room

  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true, format: { with: /\A[0-9+\-\s()]+\z/ }
  validates :preferred_date, presence: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled completed] }
  
  validate :preferred_date_in_future
  validate :preferred_date_not_too_far

  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :by_room, ->(room_id) { where(room_id: room_id) }
  scope :upcoming, -> { where('preferred_date >= ?', Time.current) }
  scope :past, -> { where('preferred_date < ?', Time.current) }

  private

  def preferred_date_in_future
    return unless preferred_date.present?
    
    if preferred_date < Time.current
      errors.add(:preferred_date, 'must be in the future')
    end
  end

  def preferred_date_not_too_far
    return unless preferred_date.present?
    
    max_days = 90 # 3 months
    if preferred_date > max_days.days.from_now
      errors.add(:preferred_date, "cannot be more than #{max_days} days in the future")
    end
  end
end
```

## 4. API Endpoints

### 4.1. POST `/api/v1/room_viewings`

**Tạo đặt lịch xem phòng mới**

**Request:**
```json
{
  "room_id": 1,
  "name": "Nguyễn Văn A",
  "email": "nguyenvana@example.com",
  "phone": "0901234567",
  "preferred_date": "2024-02-15T14:00:00Z",
  "message": "Tôi muốn xem phòng vào buổi chiều"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "room_id": 1,
  "name": "Nguyễn Văn A",
  "email": "nguyenvana@example.com",
  "phone": "0901234567",
  "preferred_date": "2024-02-15T14:00:00Z",
  "message": "Tôi muốn xem phòng vào buổi chiều",
  "status": "pending",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

**Response (422 Unprocessable Entity):**
```json
{
  "errors": {
    "name": ["can't be blank"],
    "email": ["is invalid"],
    "preferred_date": ["must be in the future"]
  }
}
```

### 4.2. GET `/api/v1/room_viewings`

**Lấy danh sách đặt lịch (với filters)**

**Query Parameters:**
- `room_id` (integer, optional): Filter theo room
- `status` (string, optional): Filter theo status (pending, confirmed, cancelled, completed)
- `page` (integer, default: 1): Pagination
- `per_page` (integer, default: 20, max: 100): Số lượng per page

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "room_id": 1,
      "name": "Nguyễn Văn A",
      "email": "nguyenvana@example.com",
      "phone": "0901234567",
      "preferred_date": "2024-02-15T14:00:00Z",
      "message": "Tôi muốn xem phòng vào buổi chiều",
      "status": "pending",
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 5,
    "total_count": 100
  }
}
```

### 4.3. GET `/api/v1/room_viewings/:id`

**Lấy chi tiết một đặt lịch**

**Response (200 OK):**
```json
{
  "id": 1,
  "room_id": 1,
  "room": {
    "id": 1,
    "title": "Phòng trọ đẹp tại Quận 1",
    "address": "123 Nguyễn Huệ, Quận 1, Hồ Chí Minh",
    "price": 5000000
  },
  "name": "Nguyễn Văn A",
  "email": "nguyenvana@example.com",
  "phone": "0901234567",
  "preferred_date": "2024-02-15T14:00:00Z",
  "message": "Tôi muốn xem phòng vào buổi chiều",
  "status": "pending",
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

### 4.4. PATCH `/api/v1/room_viewings/:id`

**Cập nhật trạng thái đặt lịch (chỉ status)**

**Request:**
```json
{
  "status": "confirmed"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "status": "confirmed",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

## 5. Controller

### 5.1. `app/controllers/api/v1/room_viewings_controller.rb`

```ruby
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
```

## 6. Routes

### 6.1. `config/routes.rb`

```ruby
namespace :api do
  namespace :v1 do
    resources :rooms, only: [:index, :show]
    resources :room_viewings, only: [:index, :show, :create, :update]
    get "addresses/suggest", to: "addresses#suggest"
    get "room_images/random", to: "room_images#random"
    get "room_images/list", to: "room_images#list"
  end
end
```

## 7. Validations & Business Rules

### 7.1. Validations
- **name**: Required, max 255 characters
- **email**: Required, valid email format
- **phone**: Required, valid phone format (numbers, +, -, spaces, parentheses)
- **preferred_date**: Required, must be in the future, max 90 days from now
- **room_id**: Required, must exist in rooms table
- **status**: Must be one of: pending, confirmed, cancelled, completed

### 7.2. Business Rules
- Không cho phép đặt lịch trong quá khứ
- Không cho phép đặt lịch quá 90 ngày trong tương lai
- Status mặc định là `pending` khi tạo mới
- Chỉ cho phép update `status` trong update action (không cho update các field khác)

## 8. Error Handling

### 8.1. Validation Errors (422)
```json
{
  "errors": {
    "field_name": ["error message"]
  }
}
```

### 8.2. Not Found (404)
```json
{
  "error": "Room viewing not found"
}
```

### 8.3. Bad Request (400)
```json
{
  "error": "Invalid parameters"
}
```

## 9. Pagination

Sử dụng gem `kaminari` (đã có trong Gemfile):
- Default: 20 items per page
- Maximum: 100 items per page
- Response includes meta information: current_page, per_page, total_pages, total_count

## 10. Security Considerations

1. **Rate Limiting**: Nên implement rate limiting để tránh spam
2. **Email Verification**: Có thể thêm email verification trong tương lai
3. **Phone Verification**: Có thể thêm SMS verification
4. **CORS**: Đã được config trong `config/initializers/cors.rb`

## 11. Future Enhancements

1. **Email Notifications**: Gửi email xác nhận khi tạo đặt lịch
2. **SMS Notifications**: Gửi SMS nhắc nhở trước ngày xem phòng
3. **Calendar Integration**: Tích hợp với Google Calendar
4. **Admin Dashboard**: Quản lý đặt lịch từ admin panel
5. **Reminder System**: Tự động gửi reminder 24h trước khi xem phòng
6. **Conflict Detection**: Kiểm tra xem có đặt lịch trùng thời gian không

## 12. Testing Considerations

1. Unit tests cho Model validations
2. Controller tests cho các actions
3. Integration tests cho API endpoints
4. Test edge cases:
   - Preferred date in the past
   - Preferred date too far in future
   - Invalid email format
   - Invalid phone format
   - Non-existent room_id

## 13. API Documentation (Swagger)

Cần thêm Swagger documentation cho:
- POST `/api/v1/room_viewings`
- GET `/api/v1/room_viewings`
- GET `/api/v1/room_viewings/:id`
- PATCH `/api/v1/room_viewings/:id`

