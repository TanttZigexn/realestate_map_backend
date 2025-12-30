# 🎨 THIẾT KẾ TÍNH NĂNG MỚI

## 1. 🔍 TÍNH NĂNG: SEARCH THEO ĐỊA CHỈ

### 1.1 Mô tả
Cho phép người dùng tìm kiếm phòng trọ bằng cách nhập địa chỉ (ví dụ: "Quận Đống Đa, Hà Nội") thay vì phải nhập tọa độ lat/lng.

### 1.2 Yêu cầu kỹ thuật

#### 1.2.1 Geocoding Service
- **Option 1: Mapbox Geocoding API** (Recommended)
  - Free tier: 100,000 requests/month
  - Tích hợp tốt với Mapbox frontend
  - Cần API key: `MAPBOX_ACCESS_TOKEN`
  
- **Option 2: Google Geocoding API**
  - Free tier: $200 credit/month (~40,000 requests)
  - Cần API key: `GOOGLE_GEOCODING_API_KEY`
  
- **Option 3: Nominatim (OpenStreetMap)** (Free, no API key)
  - Không cần API key
  - Rate limit: 1 request/second
  - Phù hợp cho development/testing

#### 1.2.2 Caching Strategy
- Cache kết quả geocoding để tránh call API nhiều lần
- Sử dụng Rails cache (Redis hoặc Memory store)
- Cache key: `geocode:#{address_hash}`
- TTL: 30 ngày (địa chỉ ít thay đổi)

#### 1.2.3 API Changes

**Thêm parameter mới vào GET /api/v1/rooms:**
- `address` (string, optional): Địa chỉ để tìm kiếm
- `address_radius` (integer, optional): Bán kính tìm kiếm từ địa chỉ (meters, default: 5000)

**Logic:**
1. Nếu có `address` → Geocode địa chỉ → Lấy lat/lng → Dùng radius search
2. Nếu có `address` + `address_radius` → Dùng radius tùy chỉnh
3. Priority: `address` > `bounding_box` > `radius` (lat/lng)

### 1.3 Database Changes
Không cần thay đổi database schema.

### 1.4 Implementation Plan

#### Step 1: Thêm Geocoding Service
- Tạo `app/services/geocoding_service.rb`
- Support nhiều providers (Mapbox, Google, Nominatim)
- Implement caching

#### Step 2: Cập nhật RoomsController
- Thêm logic xử lý `address` parameter
- Geocode address → convert sang lat/lng
- Apply radius search với lat/lng từ geocoding

#### Step 3: Error Handling
- Handle geocoding failures (address not found)
- Return error message rõ ràng

### 1.5 API Examples

```bash
# Search by address
GET /api/v1/rooms?address=Quận Đống Đa, Hà Nội

# Search by address with custom radius
GET /api/v1/rooms?address=Quận Đống Đa, Hà Nội&address_radius=10000

# Combine with filters
GET /api/v1/rooms?address=Quận Đống Đa, Hà Nội&min_price=2000000&room_type=studio
```

### 1.6 Response Format
Giữ nguyên GeoJSON FeatureCollection format.

### 1.7 Error Responses

```json
{
  "error": "Address not found: 'Invalid Address'"
}
```

---

## 2. 📝 TÍNH NĂNG: ĐĂNG KÝ XEM PHÒNG

### 2.1 Mô tả
Cho phép người dùng đăng ký xem phòng trọ, lưu thông tin liên hệ và thời gian mong muốn.

### 2.2 Yêu cầu chức năng

#### 2.2.1 Core Features
- Đăng ký xem phòng với thông tin:
  - Tên người đăng ký
  - Số điện thoại
  - Email (optional)
  - Ngày mong muốn xem
  - Giờ mong muốn xem (optional)
  - Ghi chú (optional)
- Validation: Room phải available
- Trả về confirmation message

#### 2.2.2 Optional Features (Phase 2)
- Gửi email notification cho chủ phòng
- Gửi email confirmation cho người đăng ký
- Admin panel để quản lý đăng ký
- Status tracking (pending, confirmed, cancelled)

### 2.3 Database Schema

#### 2.3.1 Tạo bảng `viewing_registrations`

```ruby
create_table :viewing_registrations do |t|
  t.references :room, null: false, foreign_key: true
  t.string :name, null: false
  t.string :phone, null: false
  t.string :email
  t.date :preferred_date, null: false
  t.time :preferred_time
  t.text :message
  t.string :status, default: 'pending' # pending, confirmed, cancelled
  t.timestamps
end

add_index :viewing_registrations, :room_id
add_index :viewing_registrations, :status
add_index :viewing_registrations, :preferred_date
```

**Fields:**
- `room_id` (bigint, required): Foreign key to rooms
- `name` (string, required): Tên người đăng ký
- `phone` (string, required): Số điện thoại
- `email` (string, optional): Email
- `preferred_date` (date, required): Ngày mong muốn xem
- `preferred_time` (time, optional): Giờ mong muốn xem
- `message` (text, optional): Ghi chú thêm
- `status` (string, default: 'pending'): Trạng thái đăng ký
- `created_at`, `updated_at` (timestamps)

### 2.4 API Design

#### 2.4.1 POST /api/v1/rooms/:id/viewing_registrations

**Request Body:**
```json
{
  "name": "Nguyễn Văn A",
  "phone": "0912345678",
  "email": "nguyenvana@example.com",
  "preferred_date": "2024-01-15",
  "preferred_time": "14:00",
  "message": "Tôi muốn xem phòng vào buổi chiều"
}
```

**Response (Success - 201 Created):**
```json
{
  "id": 1,
  "room_id": 2,
  "name": "Nguyễn Văn A",
  "phone": "0912345678",
  "email": "nguyenvana@example.com",
  "preferred_date": "2024-01-15",
  "preferred_time": "14:00:00",
  "message": "Tôi muốn xem phòng vào buổi chiều",
  "status": "pending",
  "created_at": "2024-01-10T10:00:00Z"
}
```

**Response (Error - 400 Bad Request):**
```json
{
  "error": "Validation failed",
  "errors": {
    "name": ["can't be blank"],
    "phone": ["can't be blank"],
    "preferred_date": ["can't be blank"]
  }
}
```

**Response (Error - 404 Not Found):**
```json
{
  "error": "Room not found"
}
```

**Response (Error - 422 Unprocessable Entity):**
```json
{
  "error": "Room is not available for viewing"
}
```

#### 2.4.2 GET /api/v1/rooms/:id/viewing_registrations (Optional - Admin only)

Lấy danh sách đăng ký xem phòng của một room (cần authentication sau này).

### 2.5 Model Design

#### 2.5.1 ViewingRegistration Model

```ruby
class ViewingRegistration < ApplicationRecord
  belongs_to :room

  validates :name, presence: true
  validates :phone, presence: true
  validates :preferred_date, presence: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :room_must_be_available
  validate :preferred_date_must_be_future

  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :by_date, ->(date) { where(preferred_date: date) }

  private

  def room_must_be_available
    errors.add(:room, "is not available") unless room&.status == 'available'
  end

  def preferred_date_must_be_future
    return unless preferred_date.present?
    errors.add(:preferred_date, "must be in the future") if preferred_date < Date.today
  end
end
```

#### 2.5.2 Update Room Model

```ruby
class Room < ApplicationRecord
  # ... existing code ...
  
  has_many :viewing_registrations, dependent: :destroy
end
```

### 2.6 Controller Design

#### 2.6.1 ViewingRegistrationsController

```ruby
module Api
  module V1
    class ViewingRegistrationsController < ApplicationController
      before_action :set_room

      def create
        @registration = @room.viewing_registrations.build(viewing_registration_params)
        
        if @registration.save
          render json: @registration, status: :created
        else
          render json: { error: "Validation failed", errors: @registration.errors }, 
                 status: :bad_request
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Room not found" }, status: :not_found
      end

      private

      def set_room
        @room = Room.find(params[:room_id])
      end

      def viewing_registration_params
        params.require(:viewing_registration).permit(
          :name, :phone, :email, :preferred_date, 
          :preferred_time, :message
        )
      end
    end
  end
end
```

### 2.7 Routes Design

```ruby
namespace :api do
  namespace :v1 do
    resources :rooms, only: [:index, :show] do
      resources :viewing_registrations, only: [:create], 
                path: 'viewing-registrations'
    end
  end
end
```

**Routes:**
- `POST /api/v1/rooms/:room_id/viewing-registrations`

### 2.8 Validation Rules

1. **Required fields:**
   - name: không được để trống
   - phone: không được để trống
   - preferred_date: không được để trống

2. **Business rules:**
   - Room phải có status = 'available'
   - preferred_date phải là ngày trong tương lai
   - Email format phải đúng (nếu có)

3. **Phone validation:**
   - Format: số điện thoại Việt Nam (10-11 số)
   - Hoặc chấp nhận format linh hoạt

### 2.9 Error Handling

- **Room not found** → 404
- **Room not available** → 422
- **Validation errors** → 400 với error details
- **Invalid date format** → 400

### 2.10 Security Considerations

- Rate limiting: Giới hạn số lượng đăng ký từ cùng một IP/phone
- Input sanitization: Xử lý XSS trong message field
- Spam prevention: Có thể thêm CAPTCHA sau này

---

## 3. 📋 IMPLEMENTATION CHECKLIST

### 3.1 Search theo địa chỉ

- [ ] Tạo GeocodingService với support nhiều providers
- [ ] Implement caching cho geocoding results
- [ ] Cập nhật RoomsController để xử lý `address` parameter
- [ ] Add error handling cho geocoding failures
- [ ] Update API documentation
- [ ] Test với các địa chỉ khác nhau
- [ ] Test caching mechanism

### 3.2 Đăng ký xem phòng

- [ ] Tạo migration cho `viewing_registrations` table
- [ ] Tạo ViewingRegistration model với validations
- [ ] Update Room model (add association)
- [ ] Tạo ViewingRegistrationsController
- [ ] Add routes
- [ ] Implement error handling
- [ ] Test API endpoints
- [ ] Update API documentation

---

## 4. 🔄 MIGRATION ORDER

1. **First:** Implement Search theo địa chỉ (không cần database changes)
2. **Second:** Implement Đăng ký xem phòng (cần database migration)

---

## 5. 📝 ENVIRONMENT VARIABLES

Thêm vào `.env` hoặc `config/application.yml`:

```bash
# Geocoding Service (chọn 1)
MAPBOX_ACCESS_TOKEN=your_mapbox_token
# HOẶC
GOOGLE_GEOCODING_API_KEY=your_google_key
# HOẶC (không cần key cho Nominatim)
```

---

## 6. 🧪 TESTING SCENARIOS

### 6.1 Search theo địa chỉ

- ✅ Search với địa chỉ hợp lệ
- ✅ Search với địa chỉ không tìm thấy
- ✅ Search với address + filters
- ✅ Test caching (geocode cùng địa chỉ 2 lần)
- ✅ Test với các providers khác nhau

### 6.2 Đăng ký xem phòng

- ✅ Đăng ký thành công
- ✅ Đăng ký với room không tồn tại
- ✅ Đăng ký với room đã rented
- ✅ Đăng ký với preferred_date trong quá khứ
- ✅ Đăng ký thiếu required fields
- ✅ Đăng ký với email không hợp lệ

---

## 7. 📚 API DOCUMENTATION UPDATES

Cần cập nhật README.md với:
- Thêm `address` parameter vào GET /rooms
- Thêm POST /rooms/:id/viewing-registrations endpoint
- Examples và error responses

---

## 8. 🚀 FUTURE ENHANCEMENTS

### 8.1 Search theo địa chỉ
- Autocomplete suggestions
- Search history
- Popular locations

### 8.2 Đăng ký xem phòng
- Email notifications
- SMS notifications
- Calendar integration
- Admin dashboard
- Status management
- Reminder emails

---

**Lưu ý:** Design này có thể được điều chỉnh trong quá trình implementation dựa trên feedback và requirements thực tế.

