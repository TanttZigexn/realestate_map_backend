class RoomImageService
  IMAGES_BY_TYPE = {
    'room' => [
      'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png',
      'https://cdn.chotot.com/i6GE73rBbwbG73TwEzvIP7xwBTcla4TjefA_SvwhnPQ/preset:listing/plain/ee12a977aaca396078d4cfe949bec6d9-2963911825512028863.jpg',
      'https://cdn.chotot.com/3VKtcrDGvrVVX00Uecfln5ZHiY_8KgLxWQs1dDjPDO8/preset:listing/plain/ea3d578a2d673efcdc291b06affce598-2963058991696064060.jpg',
      'https://cdn.chotot.com/f1EyvH-bSZsngdjfORsnxmJm9ap_lYH8z3hT9djynwE/preset:listing/plain/5fbeca210a131626c0be67c9bb16a277-2956169538949598691.jpg',
      'https://cdn.chotot.com/rxjzWHSpavRteA5vl_QrlkMBTrpClw4t3ZQMrWgRWRk/preset:listing/plain/f122ac28f205ebf5c7ed8e8e3853099e-2740027741726202668.jpg',
      'https://cdn.chotot.com/fLdBwoWbMBUpeYOdY1hT1RFwQe5zPVuSZsx2dK0AK9s/preset:listing/plain/8f215bce156f1944554e9031f2e1b253-2882520510615849354.jpg'
    ],
    'studio' => [
      'https://cdn.chotot.com/IaIlnXCzRVZzNhUux_tdHNDlDvEc8a6kUSlN8KclMps/preset:view/plain/933063e96709aecf31ac859439b198b8-2962696834623167718.jpg',
      'https://cdn.chotot.com/J-VYsdYJ_ccxz6x4PykN4gR6UTtCq15Dhzos4A8egQw/preset:listing/plain/76636c79d9be00272c6a2af3f395777c-2963861538504795262.jpg',
      'https://cdn.chotot.com/Ez0zytJ-AcVzpaizKfqevwecwkwINm9TjDPcIbxtKDk/preset:listing/plain/2578cf3a421eba7fd0d52c9c74015318-2963069722976499804.jpg',
      'https://cdn.chotot.com/t4cADGsRflOFg9Ec8APJ-XalKHTX2mbxMmfh8EcpwQU/preset:listing/plain/99c01031a4ec30aab88e0b180912a461-2804502993633987791.jpg',
      'https://cdn.chotot.com/_gW50Wqhhio2psXR0g6I6BDKfqNPgW0ESZES528v0ks/preset:listing/plain/a12ae5231ec8339f018e379105eedfa2-2904635256049293044.jpg',
      'https://cdn.chotot.com/Rd66BtOB7Bs3H2t1KGtu8gEKDVegzY_mEGioKRXEtjU/preset:listing/plain/3fb3459bb452214ae451f206021fb4c0-2873922262104852665.jpg'
    ],
    'apartment' => [
      'https://decoholic.org/wp-content/uploads/2022/05/small-Scandinavian-apartment.jpg.webp',
      'https://decoholic.org/wp-content/uploads/2022/05/small-apartment-living-room-idea-2.jpg.webp',
      'https://decoholic.org/wp-content/uploads/2022/05/small-apartment-living-room.jpg.webp',
      'https://decoholic.org/wp-content/uploads/2022/05/small-apartment-living-room-1.jpg.webp',
      'https://decoholic.org/wp-content/uploads/2022/05/small-apartment-living-room-4.jpg.webp',
      'https://decoholic.org/wp-content/uploads/2022/05/small-apartment-living-room-idea.jpg.webp'
    ]
  }.freeze
  
  DEFAULT_IMAGES = [
    'http://ecogreen-saigon.vn/uploads/phong-tro-la-loai-hinh-nha-o-pho-bien-gia-re-tien-loi-cho-sinh-vien-va-nguoi-di-lam.png'
  ].freeze
  
  def self.random_image(room_type = nil)
    new.random_image(room_type)
  end
  
  def random_image(room_type = nil)
    normalized_type = room_type.to_s.downcase.strip if room_type.present?
    
    images = if normalized_type.present? && IMAGES_BY_TYPE.key?(normalized_type)
               IMAGES_BY_TYPE[normalized_type]
             else
               IMAGES_BY_TYPE.values.flatten.uniq
             end
    
    images = DEFAULT_IMAGES if images.blank?
    
    images.sample
  end
  
  def self.all_images_by_type
    IMAGES_BY_TYPE
  end
end

