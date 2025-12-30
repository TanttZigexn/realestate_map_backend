# 📋 KẾ HOẠCH THIẾT KẾ GIẢI PHÁP - REALESTATE MAP API

## 1. MỤC TIÊU & YÊU CẦU

### 1.1 Mục tiêu cuối cùng

Xây dựng một **RESTful API Backend** hoàn chỉnh cho hệ thống **Realestate Map** - Hệ thống tìm kiếm phòng trọ trên bản đồ, với các tính năng:

- **Tìm kiếm phòng trọ theo vùng địa lý** (bounding box, bán kính)
- **Lọc phòng trọ** theo nhiều tiêu chí (giá, diện tích, loại phòng, trạng thái)
- **Trả về dữ liệu GeoJSON** chuẩn Mapbox để frontend hiển thị trên bản đồ
- **Tối ưu hiệu năng** với PostGIS spatial indexing
- **Bảo mật** với input validation và SQL injection prevention
- **Mở rộng được** với kiến trúc rõ ràng, dễ maintain

### 1.2 Yêu cầu kỹ thuật

- **Framework**: Ruby on Rails 8.0.3 (API mode)
- **Database**: PostgreSQL 16+ với PostGIS extension
- **Format trả về**: GeoJSON FeatureCollection (chuẩn Mapbox)
- **API Versioning**: `/api/v1/`
- **CORS**: Hỗ trợ cross-origin requests
- **Security**: Input validation, parameter sanitization, rate limiting ready
- **Performance**: Spatial indexing (GIST), query optimization, result limiting

### 1.3 Phạm vi dự án

**Trong phạm vi:**
- ✅ Backend API endpoints cho rooms
- ✅ PostGIS spatial queries (bounding box, radius)
- ✅ Filtering (price, area, room_type, status)
- ✅ GeoJSON response format
- ✅ Database schema với PostGIS
- ✅ Seed data mẫu
- ✅ CORS configuration

**Ngoài phạm vi (Phase 2+):**
- ❌ User authentication/authorization
- ❌ CRUD operations (create, update, delete rooms)
- ❌ Image uploads
- ❌ Booking/reservation system
- ❌ Payment integration
- ❌ Admin panel

---

## 2. KẾ HOẠCH TRIỂN KHAI CHI TIẾT

### BƯỚC 1: Cài đặt Dependencies & PostGIS Extension

#### Files changed:
- `Gemfile`
- `config/database.yml` (đã có sẵn)
- `db/migrate/XXXXXX_enable_postgis_extension.rb` (mới tạo)

#### Changes content (TODO List):
1. Thêm các gems cần thiết vào Gemfile:
   - `rgeo` - Xử lý dữ liệu địa lý
   - `rgeo-geojson` - Chuyển đổi sang GeoJSON
   - `activerecord-postgis-adapter` - PostGIS adapter cho ActiveRecord
   - `rack-cors` - CORS support
   - `kaminari` hoặc `pagy` - Pagination (optional)

2. Tạo migration để enable PostGIS extension trong PostgreSQL

3. Chạy `bundle install` để cài đặt gems

4. Verify PostGIS extension đã được enable

#### Implementation (Code Sample):

```ruby
# Gemfile - Thêm vào cuối file
gem 'rgeo'
gem 'rgeo-geojson'
gem 'activerecord-postgis-adapter'
gem 'rack-cors'
gem 'kaminari' # hoặc gem 'pagy'
```

```ruby
# db/migrate/XXXXXX_enable_postgis_extension.rb
class EnablePostgisExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'postgis' unless extension_enabled?('postgis')
  end
end
```

```bash
# Terminal commands
bundle install
rails db:migrate
```

---

### BƯỚC 2: Tạo Database Schema - Rooms Model

#### Files changed:
- `db/migrate/XXXXXX_create_rooms.rb` (mới tạo)
- `app/models/room.rb` (mới tạo)
- `app/models/concerns/geojson_convertible.rb` (mới tạo - optional concern)

#### Changes content (TODO List):
1. Tạo migration cho bảng `rooms` với các fields:
   - `title` (string, required)
   - `price` (integer, required)
   - `area` (float, optional)
   - `address` (text, optional)
   - `latitude` (float, required)
   - `longitude` (float, required)
   - `location` (geography Point - PostGIS, required)
   - `room_type` (string: room/studio/apartment)
   - `status` (string: available/rented, default: available)
   - `description` (text, optional)
   - `phone` (string, optional)
   - `created_at`, `updated_at` (timestamps)

2. Tạo indexes:
   - GIST index cho `location` (bắt buộc cho spatial queries)
   - BTREE indexes cho `price`, `status`, `room_type` (tối ưu filtering)

3. Tạo Room model với:
   - Validations (title, price, latitude, longitude, status)
   - Callbacks (set_location từ lat/lng trước khi save)
   - Scopes cho filtering (available, by_room_type, price_between, area_between)
   - PostGIS scopes (within_bounds, within_radius)
   - GeoJSON conversion methods (to_geojson_feature, to_geojson_feature_collection)

4. Implement phone formatting helper

#### Implementation (Code Sample):

```ruby
# db/migrate/XXXXXX_create_rooms.rb
class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :title, null: false
      t.integer :price, null: false
      t.float :area
      t.text :address
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :room_type
      t.string :status, default: 'available'
      t.text :description
      t.string :phone

      t.timestamps
    end

    # Add PostGIS geography column
    add_column :rooms, :location, :geography, limit: { srid: 4326, type: "point" }

    # Add indexes for performance
    add_index :rooms, :location, using: :gist
    add_index :rooms, :price
    add_index :rooms, :status
    add_index :rooms, :room_type
  end
end
```

```ruby
# app/models/room.rb
class Room < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :latitude, presence: true, numericality: { in: -90.0..90.0 }
  validates :longitude, presence: true, numericality: { in: -180.0..180.0 }
  validates :status, inclusion: { in: %w[available rented] }
  validates :room_type, inclusion: { in: %w[room studio apartment] }, allow_nil: true

  # Callbacks
  before_save :set_location_from_coordinates

  # Scopes for filtering
  scope :available, -> { where(status: 'available') }
  scope :by_room_type, ->(type) { where(room_type: type) if type.present? }
  scope :price_between, ->(min, max) {
    query = all
    query = query.where('price >= ?', min) if min.present? && min.to_f > 0
    query = query.where('price <= ?', max) if max.present? && max.to_f > 0
    query
  }
  scope :area_between, ->(min, max) {
    query = all
    query = query.where('area >= ?', min) if min.present? && min.to_f > 0
    query = query.where('area <= ?', max) if max.present? && max.to_f > 0
    query
  }

  # PostGIS spatial queries
  scope :within_bounds, ->(north, south, east, west) {
    where(
      "location && ST_MakeEnvelope(?, ?, ?, ?, 4326)",
      west.to_f, south.to_f, east.to_f, north.to_f
    )
  }

  scope :within_radius, ->(lat, lng, radius) {
    where(
      "ST_DWithin(location, ST_MakePoint(?, ?)::geography, ?)",
      lng.to_f, lat.to_f, radius.to_f
    )
  }

  # GeoJSON conversion (Mapbox standard format)
  def to_geojson_feature
    {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [longitude, latitude] # GeoJSON: [lng, lat]
      },
      properties: {
        id: id,
        title: title,
        price: price,
        area: area,
        address: address,
        roomType: room_type,
        status: status,
        description: description,
        phone: phone,
        phoneFormatted: phone_formatted
      }
    }
  end

  def self.to_geojson_feature_collection(rooms)
    {
      type: "FeatureCollection",
      features: rooms.map(&:to_geojson_feature)
    }
  end

  # Helper methods
  def phone_formatted
    return nil unless phone.present?
    # Format: (024) 1234-5678
    phone.gsub(/(\d{2,4})(\d{4})(\d{4})/, '(\1) \2-\3')
  end

  private

  def set_location_from_coordinates
    if latitude.present? && longitude.present?
      # PostGIS POINT format: POINT(lng lat)
      self.location = "POINT(#{longitude} #{latitude})"
    end
  end
end
```

```bash
# Terminal commands
rails db:migrate
```

---

### BƯỚC 3: Tạo Seed Data Mẫu

#### Files changed:
- `db/seeds.rb` (cập nhật)

#### Changes content (TODO List):
1. Xóa dữ liệu cũ (nếu có)
2. Tạo 20-30 phòng mẫu tập trung tại Hà Nội hoặc TP.HCM
3. Đa dạng về:
   - Giá (1.5M - 8M VNĐ)
   - Diện tích (12 - 60 m²)
   - Loại phòng (room, studio, apartment)
   - Trạng thái (75% available, 25% rented)
4. Sử dụng tọa độ thật của các địa điểm tại Hà Nội/TP.HCM

#### Implementation (Code Sample):

```ruby
# db/seeds.rb
puts "🧹 Clearing existing data..."
Room.destroy_all

puts "🏠 Creating sample rooms..."

# Hanoi sample locations
hanoi_rooms = [
  { title: "Studio cozy gần Hồ Tây", lat: 21.0545, lng: 105.8189, price: 3500000, area: 25, type: "studio", phone: "02438345678" },
  { title: "Phòng trọ sinh viên Đống Đa", lat: 21.0245, lng: 105.8412, price: 2000000, area: 18, type: "room", phone: "02438123456" },
  { title: "Căn hộ 1PN Cầu Giấy", lat: 21.0333, lng: 105.7943, price: 5000000, area: 45, type: "apartment", phone: "02437654321" },
  { title: "Phòng đẹp có ban công Hai Bà Trưng", lat: 21.0122, lng: 105.8589, price: 3000000, area: 22, type: "room", phone: "02438567890" },
  { title: "Studio full nội thất Tây Hồ", lat: 21.0652, lng: 105.8231, price: 4500000, area: 30, type: "studio", phone: "02438234567" },
  { title: "Nhà trọ giá rẻ Thanh Xuân", lat: 20.9967, lng: 105.8053, price: 1800000, area: 15, type: "room", phone: "02437890123" },
  { title: "Căn hộ dịch vụ Hoàn Kiếm", lat: 21.0285, lng: 105.8542, price: 8000000, area: 60, type: "apartment", phone: "02438901234" },
  { title: "Phòng trọ có gác Long Biên", lat: 21.0451, lng: 105.8932, price: 2500000, area: 20, type: "room", phone: "02438112233" },
  { title: "Studio view hồ Ba Đình", lat: 21.0351, lng: 105.8190, price: 4000000, area: 28, type: "studio", phone: "02438334455" },
  { title: "Phòng ở ghép Nam Từ Liêm", lat: 21.0411, lng: 105.7564, price: 1500000, area: 12, type: "room", phone: "02437556677" },
]

hanoi_rooms.each_with_index do |room_data, index|
  Room.create!(
    title: room_data[:title],
    price: room_data[:price],
    area: room_data[:area],
    address: "#{100 + index} Đường ABC, #{['Quận Đống Đa', 'Quận Cầu Giấy', 'Quận Hai Bà Trưng', 'Quận Tây Hồ', 'Quận Hoàn Kiếm', 'Quận Long Biên', 'Quận Ba Đình', 'Quận Nam Từ Liêm'].sample}, Hà Nội",
    latitude: room_data[:lat],
    longitude: room_data[:lng],
    room_type: room_data[:type],
    status: ['available', 'available', 'available', 'rented'].sample,
    phone: room_data[:phone],
    description: "Phòng #{room_data[:type]} tại #{room_data[:title]}. Gần trường học, siêu thị, bệnh viện. Đầy đủ tiện nghi."
  )
end

# Add more random rooms around Hanoi
20.times do |i|
  Room.create!(
    title: "Phòng trọ ##{i + 11}",
    price: rand(1500000..7000000),
    area: rand(15..50),
    address: "#{200 + i} Đường XYZ, #{['Quận Đống Đa', 'Quận Cầu Giấy', 'Quận Hai Bà Trưng', 'Quận Tây Hồ'].sample}, Hà Nội",
    latitude: 21.0285 + rand(-0.05..0.05),
    longitude: 105.8542 + rand(-0.05..0.05),
    room_type: ['room', 'studio', 'apartment'].sample,
    status: ['available', 'available', 'available', 'rented'].sample,
    phone: "024#{rand(30000000..39999999)}",
    description: "Phòng trọ tiện nghi, đầy đủ nội thất. Gần trung tâm thành phố."
  )
end

puts "✅ Created #{Room.count} rooms!"
puts "📊 Available: #{Room.available.count}"
puts "📊 Rented: #{Room.where(status: 'rented').count}"
puts "\n🎯 Sample GeoJSON Feature:"
puts Room.first.to_geojson_feature.to_json
```

```bash
# Terminal command
rails db:seed
```

---

### BƯỚC 4: Cấu hình CORS

#### Files changed:
- `config/initializers/cors.rb` (mới tạo hoặc cập nhật)

#### Changes content (TODO List):
1. Tạo initializer cho CORS configuration
2. Cho phép tất cả origins trong development (hoặc chỉ định domain cụ thể)
3. Cho phép các methods: GET, POST, OPTIONS
4. Expose headers cần thiết

#### Implementation (Code Sample):

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow all origins
    # In production, specify your frontend domain
    origins Rails.env.development? ? '*' : ENV.fetch('ALLOWED_ORIGINS', 'https://yourdomain.com')

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Content-Type', 'Authorization']
  end
end
```

---

### BƯỚC 5: Tạo API Routes

#### Files changed:
- `config/routes.rb` (cập nhật)

#### Changes content (TODO List):
1. Tạo namespace `/api/v1/` cho versioning
2. Định nghĩa routes cho rooms:
   - `GET /api/v1/rooms` - List rooms với filters
   - `GET /api/v1/rooms/:id` - Show room detail
3. Giữ health check route

#### Implementation (Code Sample):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :rooms, only: [:index, :show]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  get '/health', to: proc { [200, {}, ['OK']] }
end
```

---

### BƯỚC 6: Tạo API Controller với Filters

#### Files changed:
- `app/controllers/api/v1/rooms_controller.rb` (mới tạo)
- `app/controllers/api/v1/base_controller.rb` (mới tạo - optional)

#### Changes content (TODO List):
1. Tạo `Api::V1::BaseController` kế thừa `ApplicationController` (optional)
2. Tạo `Api::V1::RoomsController` với:
   - `index` action:
     - Nhận parameters: north, south, east, west (bounding box) HOẶC lat, lng, radius
     - Nhận filters: min_price, max_price, min_area, max_area, room_type, status
     - Apply geo filters (bounding box hoặc radius)
     - Apply attribute filters (price, area, room_type, status)
     - Limit results (max 100 để tránh overload)
     - Trả về GeoJSON FeatureCollection
   - `show` action:
     - Tìm room theo ID
     - Trả về GeoJSON Feature
     - Handle not found error
3. Implement parameter validation và sanitization
4. Add error handling

#### Implementation (Code Sample):

```ruby
# app/controllers/api/v1/base_controller.rb (Optional - for shared logic)
module Api
  module V1
    class BaseController < ApplicationController
      # Shared logic for API v1 controllers
      # E.g., authentication, rate limiting, etc.
    end
  end
end
```

```ruby
# app/controllers/api/v1/rooms_controller.rb
module Api
  module V1
    class RoomsController < ApplicationController
      MAX_RESULTS = 100

      def index
        @rooms = Room.all

        # Apply geographic filters (bounding box OR radius)
        @rooms = apply_geo_filters(@rooms)

        # Apply attribute filters
        @rooms = apply_attribute_filters(@rooms)

        # Limit results for performance
        @rooms = @rooms.limit(MAX_RESULTS)

        # Return GeoJSON FeatureCollection
        render json: Room.to_geojson_feature_collection(@rooms)
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      end

      def show
        @room = Room.find(params[:id])
        render json: @room.to_geojson_feature
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Room not found' }, status: :not_found
      end

      private

      def apply_geo_filters(scope)
        # Bounding box filter (priority over radius)
        if bounding_box_params_present?
          validate_bounding_box_params!
          scope = scope.within_bounds(
            params[:north].to_f,
            params[:south].to_f,
            params[:east].to_f,
            params[:west].to_f
          )
        # Radius filter
        elsif radius_params_present?
          validate_radius_params!
          scope = scope.within_radius(
            params[:lat].to_f,
            params[:lng].to_f,
            params[:radius].to_f
          )
        end

        scope
      end

      def apply_attribute_filters(scope)
        # Price filter
        scope = scope.price_between(
          params[:min_price],
          params[:max_price]
        )

        # Area filter
        scope = scope.area_between(
          params[:min_area],
          params[:max_area]
        )

        # Room type filter
        scope = scope.by_room_type(params[:room_type])

        # Status filter (default to available if not specified)
        scope = scope.where(status: params[:status]) if params[:status].present?

        scope
      end

      def bounding_box_params_present?
        params[:north].present? && params[:south].present? &&
        params[:east].present? && params[:west].present?
      end

      def radius_params_present?
        params[:lat].present? && params[:lng].present? && params[:radius].present?
      end

      def validate_bounding_box_params!
        north = params[:north].to_f
        south = params[:south].to_f
        east = params[:east].to_f
        west = params[:west].to_f

        raise ArgumentError, "Invalid bounding box: north must be > south" if north <= south
        raise ArgumentError, "Invalid bounding box: east must be > west" if east <= west
        raise ArgumentError, "Invalid latitude: must be between -90 and 90" if north.abs > 90 || south.abs > 90
        raise ArgumentError, "Invalid longitude: must be between -180 and 180" if east.abs > 180 || west.abs > 180
      end

      def validate_radius_params!
        lat = params[:lat].to_f
        lng = params[:lng].to_f
        radius = params[:radius].to_f

        raise ArgumentError, "Invalid latitude: must be between -90 and 90" if lat.abs > 90
        raise ArgumentError, "Invalid longitude: must be between -180 and 180" if lng.abs > 180
        raise ArgumentError, "Invalid radius: must be positive" if radius <= 0
        raise ArgumentError, "Radius too large: max 50000 meters" if radius > 50000
      end
    end
  end
end
```

---

### BƯỚC 7: Cập nhật README.md với Design Documentation

#### Files changed:
- `README.md` (cập nhật)

#### Changes content (TODO List):
1. Thêm section về project overview
2. Thêm section về API endpoints documentation
3. Thêm section về database schema
4. Thêm section về setup instructions
5. Thêm section về testing

#### Implementation (Code Sample):

```markdown
# Realestate Map API

Hệ thống Backend API cho ứng dụng tìm kiếm phòng trọ trên bản đồ sử dụng Mapbox.

## 🎯 Tính năng

- Tìm kiếm phòng trọ theo vùng địa lý (bounding box, bán kính)
- Lọc phòng trọ theo giá, diện tích, loại phòng, trạng thái
- Trả về dữ liệu GeoJSON chuẩn Mapbox
- Tối ưu hiệu năng với PostGIS spatial indexing

## 🛠 Tech Stack

- **Framework**: Ruby on Rails 8.0.3 (API mode)
- **Database**: PostgreSQL 16+ với PostGIS extension
- **Ruby**: 3.3.4

## 📦 Setup

### Prerequisites

- Ruby 3.3.4
- PostgreSQL 16+ với PostGIS extension
- Docker & Docker Compose (optional)

### Installation

1. Clone repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Start server:
   ```bash
   rails server
   ```

Hoặc sử dụng Docker Compose:
```bash
docker-compose up
```

## 📡 API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

### GET /rooms

Lấy danh sách phòng trọ với filters.

**Query Parameters:**

#### Geographic Filters (chọn 1 trong 2):

**Option 1: Bounding Box**
- `north` (float, required): Vĩ độ phía bắc
- `south` (float, required): Vĩ độ phía nam
- `east` (float, required): Kinh độ phía đông
- `west` (float, required): Kinh độ phía tây

**Option 2: Radius**
- `lat` (float, required): Vĩ độ trung tâm
- `lng` (float, required): Kinh độ trung tâm
- `radius` (float, required): Bán kính tính bằng mét (max 50000)

#### Attribute Filters (optional):
- `min_price` (integer): Giá tối thiểu
- `max_price` (integer): Giá tối đa
- `min_area` (float): Diện tích tối thiểu (m²)
- `max_area` (float): Diện tích tối đa (m²)
- `room_type` (string): Loại phòng (room, studio, apartment)
- `status` (string): Trạng thái (available, rented)

**Example Requests:**

```bash
# Bounding box query
GET /api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84

# Radius query
GET /api/v1/rooms?lat=21.0285&lng=105.8542&radius=5000

# With filters
GET /api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84&min_price=2000000&max_price=5000000&room_type=studio
```

**Response Format (GeoJSON FeatureCollection):**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [105.8542, 21.0285]
      },
      "properties": {
        "id": 1,
        "title": "Studio cozy gần Hồ Tây",
        "price": 3500000,
        "area": 25,
        "address": "100 Đường ABC, Quận Đống Đa, Hà Nội",
        "roomType": "studio",
        "status": "available",
        "description": "Phòng studio tại...",
        "phone": "02438345678",
        "phoneFormatted": "(024) 3834-5678"
      }
    }
  ]
}
```

### GET /rooms/:id

Lấy thông tin chi tiết một phòng.

**Response Format (GeoJSON Feature):**

```json
{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [105.8542, 21.0285]
  },
  "properties": {
    "id": 1,
    "title": "Studio cozy gần Hồ Tây",
    "price": 3500000,
    "area": 25,
    "address": "100 Đường ABC, Quận Đống Đa, Hà Nội",
    "roomType": "studio",
    "status": "available",
    "description": "Phòng studio tại...",
    "phone": "02438345678",
    "phoneFormatted": "(024) 3834-5678"
  }
}
```

## 🗄 Database Schema

### Rooms Table

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| title | string | Tên phòng (required) |
| price | integer | Giá thuê (required) |
| area | float | Diện tích (m²) |
| address | text | Địa chỉ |
| latitude | float | Vĩ độ (required) |
| longitude | float | Kinh độ (required) |
| location | geography(Point) | PostGIS point (required) |
| room_type | string | Loại phòng (room/studio/apartment) |
| status | string | Trạng thái (available/rented) |
| description | text | Mô tả |
| phone | string | Số điện thoại |
| created_at | datetime | |
| updated_at | datetime | |

**Indexes:**
- GIST index trên `location` (spatial queries)
- BTREE indexes trên `price`, `status`, `room_type`

## 🧪 Testing

### Test với curl

```bash
# Get all rooms (no filters)
curl http://localhost:3000/api/v1/rooms

# Bounding box query
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84"

# Radius query
curl "http://localhost:3000/api/v1/rooms?lat=21.0285&lng=105.8542&radius=5000"

# With filters
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84&min_price=2000000&max_price=5000000&room_type=studio"

# Get single room
curl http://localhost:3000/api/v1/rooms/1
```

### Test với Rails Console

```ruby
rails console

# Test GeoJSON conversion
room = Room.first
room.to_geojson_feature

# Test scopes
Room.within_bounds(21.04, 21.02, 105.86, 105.84)
Room.within_radius(21.0285, 105.8542, 5000)
Room.price_between(2000000, 5000000)
```

## 🔒 Security Considerations

- Input validation cho tất cả parameters
- SQL injection prevention (sử dụng parameterized queries)
- Bounding box validation (north > south, east > west)
- Radius limit (max 50000 meters)
- Result limiting (max 100 results)

## 📈 Performance Optimizations

- PostGIS GIST index cho spatial queries
- BTREE indexes cho filtering
- Result limiting (max 100)
- Query optimization với scopes

## 🚀 Deployment

Xem `docker-compose.yml` và `Dockerfile` để deploy với Docker.

## 📝 License

[Your License]
```

---

### BƯỚC 8: Step-by-step Test Sample

#### Files changed:
- `test/api/v1/rooms_test.rb` (optional - nếu dùng Rails test)
- Hoặc test manual với curl/Postman

#### Changes content (TODO List):
1. Test từng endpoint một cách tuần tự
2. Verify response format (GeoJSON)
3. Test error cases
4. Test performance với nhiều data

#### Implementation (Code Sample):

```bash
# ============================================
# STEP-BY-STEP TESTING GUIDE
# ============================================

# 1. Start server
rails server
# Hoặc
docker-compose up

# 2. Verify database có data
rails console
> Room.count
> Room.first.to_geojson_feature

# 3. Test GET /api/v1/rooms (no filters)
curl http://localhost:3000/api/v1/rooms | jq

# Expected: GeoJSON FeatureCollection với tất cả rooms

# 4. Test Bounding Box Query
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84" | jq

# Expected: Chỉ rooms trong bounding box

# 5. Test Radius Query
curl "http://localhost:3000/api/v1/rooms?lat=21.0285&lng=105.8542&radius=5000" | jq

# Expected: Chỉ rooms trong bán kính 5km

# 6. Test Price Filter
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84&min_price=2000000&max_price=5000000" | jq

# Expected: Rooms với giá từ 2M đến 5M

# 7. Test Room Type Filter
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84&room_type=studio" | jq

# Expected: Chỉ studio rooms

# 8. Test Combined Filters
curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84&min_price=2000000&max_price=5000000&room_type=studio&status=available" | jq

# Expected: Studio rooms, available, giá 2M-5M, trong bounding box

# 9. Test GET /api/v1/rooms/:id
curl http://localhost:3000/api/v1/rooms/1 | jq

# Expected: GeoJSON Feature của room ID 1

# 10. Test Error Cases

# Invalid bounding box (north < south)
curl "http://localhost:3000/api/v1/rooms?north=21.02&south=21.04&east=105.86&west=105.84"

# Expected: 400 Bad Request với error message

# Invalid radius (too large)
curl "http://localhost:3000/api/v1/rooms?lat=21.0285&lng=105.8542&radius=100000"

# Expected: 400 Bad Request với error message

# Room not found
curl http://localhost:3000/api/v1/rooms/99999

# Expected: 404 Not Found

# 11. Test CORS (từ browser console)
fetch('http://localhost:3000/api/v1/rooms')
  .then(r => r.json())
  .then(console.log)

# Expected: Không có CORS error, data trả về

# 12. Test Performance
time curl "http://localhost:3000/api/v1/rooms?north=21.04&south=21.02&east=105.86&west=105.84"

# Expected: Response time < 500ms với 30 rooms
```

---

## 📋 TÓM TẮT CHECKLIST TRIỂN KHAI

### Phase 1: Setup & Dependencies
- [ ] Cài đặt gems (rgeo, rgeo-geojson, activerecord-postgis-adapter, rack-cors)
- [ ] Enable PostGIS extension
- [ ] Verify PostGIS hoạt động

### Phase 2: Database & Models
- [ ] Tạo migration cho rooms table
- [ ] Tạo Room model với validations
- [ ] Implement PostGIS scopes
- [ ] Implement GeoJSON conversion methods
- [ ] Run migrations

### Phase 3: Seed Data
- [ ] Tạo seed data với 20-30 phòng
- [ ] Verify data đã được tạo

### Phase 4: API Controllers
- [ ] Tạo routes
- [ ] Tạo RoomsController
- [ ] Implement index action với filters
- [ ] Implement show action
- [ ] Add error handling

### Phase 5: Configuration
- [ ] Configure CORS
- [ ] Test CORS hoạt động

### Phase 6: Documentation & Testing
- [ ] Update README.md
- [ ] Test tất cả endpoints
- [ ] Verify GeoJSON format
- [ ] Test error cases

---

## ✅ KẾT QUẢ MONG ĐỢI

Sau khi hoàn thành tất cả các bước, bạn sẽ có:

1. ✅ **Backend API hoàn chỉnh** với endpoints `/api/v1/rooms`
2. ✅ **PostGIS spatial queries** hoạt động (bounding box, radius)
3. ✅ **Filtering system** đầy đủ (price, area, room_type, status)
4. ✅ **GeoJSON response** chuẩn Mapbox
5. ✅ **Database schema** với spatial indexing
6. ✅ **Seed data** để test
7. ✅ **CORS configuration** cho frontend integration
8. ✅ **Documentation** đầy đủ trong README
9. ✅ **Error handling** và input validation
10. ✅ **Performance optimization** với indexes

---

**Lưu ý quan trọng:**
- Tất cả code phải tuân thủ Rails best practices
- Sử dụng parameterized queries để tránh SQL injection
- Validate tất cả input parameters
- Limit kết quả trả về để tránh overload
- GeoJSON format phải đúng chuẩn: `[lng, lat]` (không phải `[lat, lng]`)

