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
