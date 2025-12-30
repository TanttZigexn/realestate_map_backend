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
  { title: "Phòng ở ghép Nam Từ Liêm", lat: 21.0411, lng: 105.7564, price: 1500000, area: 12, type: "room", phone: "02437556677" }
]

hanoi_rooms.each_with_index do |room_data, index|
  Room.create!(
    title: room_data[:title],
    price: room_data[:price],
    area: room_data[:area],
    address: "#{100 + index} Đường ABC, #{[ 'Quận Đống Đa', 'Quận Cầu Giấy', 'Quận Hai Bà Trưng', 'Quận Tây Hồ', 'Quận Hoàn Kiếm', 'Quận Long Biên', 'Quận Ba Đình', 'Quận Nam Từ Liêm' ].sample}, Hà Nội",
    latitude: room_data[:lat],
    longitude: room_data[:lng],
    room_type: room_data[:type],
    status: [ 'available', 'available', 'available', 'rented' ].sample,
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
    address: "#{200 + i} Đường XYZ, #{[ 'Quận Đống Đa', 'Quận Cầu Giấy', 'Quận Hai Bà Trưng', 'Quận Tây Hồ' ].sample}, Hà Nội",
    latitude: 21.0285 + rand(-0.05..0.05),
    longitude: 105.8542 + rand(-0.05..0.05),
    room_type: [ 'room', 'studio', 'apartment' ].sample,
    status: [ 'available', 'available', 'available', 'rented' ].sample,
    phone: "024#{rand(30000000..39999999)}",
    description: "Phòng trọ tiện nghi, đầy đủ nội thất. Gần trung tâm thành phố."
  )
end

puts "✅ Created #{Room.count} rooms!"
puts "📊 Available: #{Room.available.count}"
puts "📊 Rented: #{Room.where(status: 'rented').count}"
puts "\n🎯 Sample GeoJSON Feature:"
puts Room.first.to_geojson_feature.to_json
