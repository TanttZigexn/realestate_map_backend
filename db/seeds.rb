# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "🧹 Clearing existing data..."
Room.destroy_all

puts "🏠 Creating sample rooms..."
puts "📍 Using Mapbox Reverse Geocoding API to get real addresses..."
puts "⏱️  This will take approximately 5-10 minutes for 900 rooms (with rate limiting)"
puts ""

# Real coordinates for districts in each city
CITIES = {
  hanoi: {
    name: "Hà Nội",
    districts: [
      { name: "Quận Hoàn Kiếm", lat: 21.0285, lng: 105.8542 },
      { name: "Quận Đống Đa", lat: 21.0245, lng: 105.8412 },
      { name: "Quận Ba Đình", lat: 21.0351, lng: 105.8190 },
      { name: "Quận Hai Bà Trưng", lat: 21.0122, lng: 105.8589 },
      { name: "Quận Hoàng Mai", lat: 20.9783, lng: 105.8578 },
      { name: "Quận Thanh Xuân", lat: 20.9967, lng: 105.8053 },
      { name: "Quận Long Biên", lat: 21.0451, lng: 105.8932 },
      { name: "Quận Nam Từ Liêm", lat: 21.0411, lng: 105.7564 },
      { name: "Quận Bắc Từ Liêm", lat: 21.0756, lng: 105.7574 },
      { name: "Quận Tây Hồ", lat: 21.0652, lng: 105.8231 },
      { name: "Quận Cầu Giấy", lat: 21.0333, lng: 105.7943 },
      { name: "Quận Hà Đông", lat: 20.9724, lng: 105.7772 }
    ]
  },
  hcm: {
    name: "TP. Hồ Chí Minh",
    districts: [
      { name: "Quận 1", lat: 10.7769, lng: 106.7009 },
      { name: "Quận 2", lat: 10.7872, lng: 106.7498 },
      { name: "Quận 3", lat: 10.7830, lng: 106.6961 },
      { name: "Quận 4", lat: 10.7575, lng: 106.7017 },
      { name: "Quận 5", lat: 10.7540, lng: 106.6694 },
      { name: "Quận 6", lat: 10.7480, lng: 106.6352 },
      { name: "Quận 7", lat: 10.7314, lng: 106.7214 },
      { name: "Quận 8", lat: 10.7403, lng: 106.6284 },
      { name: "Quận 9", lat: 10.8428, lng: 106.8287 },
      { name: "Quận 10", lat: 10.7679, lng: 106.6666 },
      { name: "Quận 11", lat: 10.7670, lng: 106.6534 },
      { name: "Quận 12", lat: 10.8633, lng: 106.6547 },
      { name: "Quận Bình Thạnh", lat: 10.8022, lng: 106.7147 },
      { name: "Quận Tân Bình", lat: 10.8014, lng: 106.6526 },
      { name: "Quận Tân Phú", lat: 10.7902, lng: 106.6282 },
      { name: "Quận Phú Nhuận", lat: 10.7992, lng: 106.6802 },
      { name: "Quận Gò Vấp", lat: 10.8387, lng: 106.6653 },
      { name: "Quận Bình Tân", lat: 10.7654, lng: 106.6033 }
    ]
  },
  danang: {
    name: "Đà Nẵng",
    districts: [
      { name: "Quận Hải Châu", lat: 16.0544, lng: 108.2222 },
      { name: "Quận Thanh Khê", lat: 16.0667, lng: 108.2000 },
      { name: "Quận Sơn Trà", lat: 16.1067, lng: 108.2417 },
      { name: "Quận Ngũ Hành Sơn", lat: 16.0000, lng: 108.2500 },
      { name: "Quận Liên Chiểu", lat: 16.0833, lng: 108.1500 },
      { name: "Quận Cẩm Lệ", lat: 16.0167, lng: 108.2167 }
    ]
  }
}

ROOM_TYPES = [ 'room', 'studio', 'apartment' ]
STATUSES = [ 'available', 'available', 'available', 'rented' ] # 75% available, 25% rented

def generate_phone(city)
  case city
  when :hanoi
    "024#{rand(30000000..39999999)}"
  when :hcm
    "028#{rand(20000000..29999999)}"
  when :danang
    "0236#{rand(2000000..9999999)}"
  end
end

def generate_title(room_type, district_name, index)
  titles = {
    'room' => [
      "Phòng trọ #{district_name}",
      "Nhà trọ giá rẻ #{district_name}",
      "Phòng cho thuê #{district_name}",
      "Phòng trọ sinh viên #{district_name}",
      "Phòng trọ có gác #{district_name}",
      "Phòng ở ghép #{district_name}"
    ],
    'studio' => [
      "Studio #{district_name}",
      "Studio full nội thất #{district_name}",
      "Studio view đẹp #{district_name}",
      "Studio cozy #{district_name}",
      "Studio hiện đại #{district_name}"
    ],
    'apartment' => [
      "Căn hộ #{district_name}",
      "Căn hộ dịch vụ #{district_name}",
      "Căn hộ 1PN #{district_name}",
      "Căn hộ 2PN #{district_name}",
      "Chung cư #{district_name}"
    ]
  }
  titles[room_type].sample + " ##{index}"
end

def generate_description(room_type, district_name, city_name)
  descriptions = [
    "Phòng #{room_type} tại #{district_name}, #{city_name}. Gần trường học, siêu thị, bệnh viện. Đầy đủ tiện nghi.",
    "Phòng #{room_type} tiện nghi tại #{district_name}, #{city_name}. Gần trung tâm thành phố, thuận tiện đi lại.",
    "Phòng #{room_type} đẹp, thoáng mát tại #{district_name}, #{city_name}. Đầy đủ nội thất cơ bản.",
    "Phòng #{room_type} giá tốt tại #{district_name}, #{city_name}. An ninh, yên tĩnh, phù hợp cho sinh viên và người đi làm.",
    "Phòng #{room_type} mới, sạch sẽ tại #{district_name}, #{city_name}. Gần chợ, siêu thị, bệnh viện."
  ]
  descriptions.sample
end

def get_real_address(latitude, longitude, district_name, city_name)
  begin
    result = GeocodingService.reverse_geocode(latitude, longitude, country: "vn")
    if result && result[:formatted_address]
      # Use the real address from Mapbox
      return result[:formatted_address]
    end
  rescue StandardError => e
    puts "  ⚠️  Reverse geocoding failed for (#{latitude}, #{longitude}): #{e.message}"
  end

  # Fallback to generated address if reverse geocoding fails
  "#{rand(1..999)} #{[ 'Đường', 'Phố', 'Ngõ', 'Ngách' ].sample} #{[ 'ABC', 'XYZ', '123', 'Main', 'Center' ].sample}, #{district_name}, #{city_name}"
end

# Generate 300 rooms for each city
CITIES.each do |city_key, city_data|
  puts "\n📍 Creating 300 rooms for #{city_data[:name]}..."

  rooms_per_district = (300.0 / city_data[:districts].length).ceil
  api_call_count = 0
  # Get real addresses for all rooms (300 per city = 900 total)
  # Mapbox free tier: 100k requests/month, so 900 is safe
  max_api_calls_per_city = 300

  city_data[:districts].each_with_index do |district, district_index|
    rooms_per_district.times do |i|
      break if Room.where("address LIKE ?", "%#{city_data[:name]}%").count >= 300

      room_type = ROOM_TYPES.sample
      base_lat = district[:lat]
      base_lng = district[:lng]

      # Add random variation to coordinates (within ~2km radius)
      lat = base_lat + rand(-0.018..0.018) # ~2km
      lng = base_lng + rand(-0.018..0.018) # ~2km

      # Get real address from Mapbox (with rate limiting)
      current_city_count = Room.where("address LIKE ?", "%#{city_data[:name]}%").count
      if api_call_count < max_api_calls_per_city && current_city_count < max_api_calls_per_city
        begin
          address = get_real_address(lat, lng, district[:name], city_data[:name])
          api_call_count += 1
          # Small delay to avoid rate limiting (Mapbox free tier: 100k requests/month)
          # Delay 0.2 seconds every 5 calls to stay under rate limit
          sleep(0.2) if api_call_count % 5 == 0
        rescue StandardError
          # Fallback if API call fails
          address = "#{rand(1..999)} #{[ 'Đường', 'Phố', 'Ngõ', 'Ngách' ].sample} #{[ 'ABC', 'XYZ', '123', 'Main', 'Center' ].sample}, #{district[:name]}, #{city_data[:name]}"
        end
      else
        # Fallback to generated address if API limit reached
        address = "#{rand(1..999)} #{[ 'Đường', 'Phố', 'Ngõ', 'Ngách' ].sample} #{[ 'ABC', 'XYZ', '123', 'Main', 'Center' ].sample}, #{district[:name]}, #{city_data[:name]}"
      end

      # Price ranges by city and room type
      price = case city_key
      when :hanoi
        case room_type
        when 'room' then rand(1500000..4000000)
        when 'studio' then rand(3000000..6000000)
        when 'apartment' then rand(5000000..10000000)
        end
      when :hcm
        case room_type
        when 'room' then rand(2000000..5000000)
        when 'studio' then rand(4000000..8000000)
        when 'apartment' then rand(6000000..15000000)
        end
      when :danang
        case room_type
        when 'room' then rand(1200000..3500000)
        when 'studio' then rand(2500000..5500000)
        when 'apartment' then rand(4000000..9000000)
        end
      end

      # Area based on room type
      area = case room_type
      when 'room' then rand(12..25)
      when 'studio' then rand(20..35)
      when 'apartment' then rand(35..70)
      end

      room_index = district_index * rooms_per_district + i + 1

      Room.create!(
        title: generate_title(room_type, district[:name], room_index),
        price: price,
        area: area,
        address: address,
        latitude: lat,
        longitude: lng,
        room_type: room_type,
        status: STATUSES.sample,
        phone: generate_phone(city_key),
        description: generate_description(room_type, district[:name], city_data[:name])
      )

      # Progress indicator
      if (district_index * rooms_per_district + i + 1) % 50 == 0
        puts "  ✓ Created #{district_index * rooms_per_district + i + 1} rooms..."
      end
    end
  end

  puts "  ✅ Completed #{city_data[:name]}: #{Room.where('address LIKE ?', "%#{city_data[:name]}%").count} rooms"
end

puts "\n✅ Created #{Room.count} rooms!"
puts "📊 Breakdown by city:"
CITIES.each do |city_key, city_data|
  count = Room.where("address LIKE ?", "%#{city_data[:name]}%").count
  puts "   #{city_data[:name]}: #{count} rooms"
end
puts "\n📊 Breakdown by status:"
puts "   Available: #{Room.available.count}"
puts "   Rented: #{Room.where(status: 'rented').count}"
puts "\n📊 Breakdown by room type:"
ROOM_TYPES.each do |type|
  count = Room.where(room_type: type).count
  puts "   #{type.capitalize}: #{count} rooms"
end
puts "\n🎯 Sample GeoJSON Feature:"
puts Room.first.to_geojson_feature.to_json
