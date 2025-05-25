const mongoose = require('mongoose');

// 위치 정보를 위한 GeoJSON 스키마
const pointSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    default: 'Point',
    required: true
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    required: true
  }
});

const restaurantSchema = new mongoose.Schema({
  // 카카오 고유 ID
  kakaoId: {
    type: String,
    required: true,
    unique: true
  },
  // 음식점 이름
  name: {
    type: String,
    required: true
  },
  // 주소 정보
  address: {
    type: String,
    required: true
  },
  roadAddress: {
    type: String
  },
  // 위치 정보 (GeoJSON 형식)
  location: {
    type: pointSchema,
    index: '2dsphere' // 지리적 인덱스 추가
  },
  // 카테고리 정보
  categoryGroupCode: String,
  categoryGroupName: String,
  categoryName: String,
  // 음식 유형 (한식, 중식 등)
  foodTypes: [String],
  // 연락처
  phone: String,
  // 상세 페이지 URL
  placeUrl: String,
  // 가격대 (저렴, 중간, 고가)
  priceRange: {
    type: String,
    enum: ['저렴', '중간', '고가'],
    default: '중간'
  },
  // 평점
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  // 좋아요 수
  likes: {
    type: Number,
    default: 0
  },
  // 리뷰
  reviews: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    username: String,
    comment: String,
    rating: Number,
    date: {
      type: Date,
      default: Date.now
    }
  }],
  // 이미지 URL 목록
  images: [String],
  // 생성 및 업데이트 시간
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// 다음 위치를 찾기 위한 카테고리 기반 추천을 위한 인덱스
restaurantSchema.index({ categoryName: 1 });
restaurantSchema.index({ foodTypes: 1 });
// 지리공간 인덱스 설정
restaurantSchema.index({ location: '2dsphere' });
const Restaurant = mongoose.model('Restaurant', restaurantSchema);

module.exports = Restaurant;