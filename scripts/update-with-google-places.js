// scripts/update-with-google-places.js
// Google Places API로 실제 음식점 이미지 가져오기

const axios = require('axios');
const mongoose = require('mongoose');
const Restaurant = require('../models/Restaurant');
const connectDB = require('../config/db');

// Google Places API 키 (실제 키로 교체 필요)
const GOOGLE_API_KEY = 'AIzaSyAcx8fQRl_AEMHT5driR966gjSfDOre6xY';

connectDB();

// Google Places Text Search로 장소 검색
async function searchGooglePlace(restaurantName, lat, lng) {
  try {
    console.log(`구글에서 "${restaurantName}" 검색 중...`);
    
    const response = await axios.get('https://maps.googleapis.com/maps/api/place/textsearch/json', {
      params: {
        query: restaurantName,
        location: `${lat},${lng}`,
        radius: 1000, // 1km 반경
        key: GOOGLE_API_KEY
      }
    });
    
    if (response.data.results && response.data.results.length > 0) {
      return response.data.results[0];
    }
    
    return null;
  } catch (error) {
    console.error(`구글 장소 검색 오류 (${restaurantName}):`, error.message);
    return null;
  }
}

// Google Places Place Details로 사진 정보 가져오기
async function getGooglePlacePhotos(placeId) {
  try {
    console.log(`장소 ID ${placeId}의 상세 정보 가져오는 중...`);
    
    const response = await axios.get('https://maps.googleapis.com/maps/api/place/details/json', {
      params: {
        place_id: placeId,
        fields: 'photos',
        key: GOOGLE_API_KEY
      }
    });
    
    const photos = response.data.result?.photos || [];
    
    // 사진 URL 생성 (최대 3개)
    const photoUrls = photos.slice(0, 3).map(photo => 
      `https://maps.googleapis.com/maps/api/place/photo?maxwidth=500&photoreference=${photo.photo_reference}&key=${GOOGLE_API_KEY}`
    );
    
    console.log(`장소 ID ${placeId}에서 ${photoUrls.length}개의 사진 발견`);
    return photoUrls;
    
  } catch (error) {
    console.error(`구글 사진 가져오기 오류 (${placeId}):`, error.message);
    return [];
  }
}

// 카테고리별 기본 이미지 (백업용)
const categoryFallbacks = {
  '한식': 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=500',
  '중식': 'https://images.unsplash.com/photo-1526318896980-cf78c088247c?w=500',
  '일식': 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=500',
  '양식': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500',
  '카페': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500',
  '치킨': 'https://images.unsplash.com/photo-1562967914-608f82629710?w=500',
  '피자': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
  '족발': 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=500',
  '분식': 'https://images.unsplash.com/photo-1583471841470-bb1b5cd33bb5?w=500',
  '해산물': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500',
  '고기': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=500',
  '디저트': 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=500'
};

function getFallbackImage(restaurant) {
  for (const foodType of restaurant.foodTypes || []) {
    if (categoryFallbacks[foodType]) {
      return [categoryFallbacks[foodType]];
    }
  }
  
  const categoryName = restaurant.categoryName || '';
  for (const [key, imageUrl] of Object.entries(categoryFallbacks)) {
    if (categoryName.includes(key)) {
      return [imageUrl];
    }
  }
  
  return ['https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=500'];
}

// 모든 음식점의 이미지를 Google Places로 업데이트
async function updateWithGooglePlaces() {
  try {
    console.log('Google Places API로 음식점 이미지 업데이트 시작...');
    console.log('API 키 확인:', GOOGLE_API_KEY ? '설정됨' : '설정 안됨');
    
    if (!GOOGLE_API_KEY || GOOGLE_API_KEY === 'your-google-places-api-key') {
      console.error('Google Places API 키를 설정해주세요!');
      return;
    }
    
    const restaurants = await Restaurant.find({});
    console.log(`총 ${restaurants.length}개 음식점 업데이트 중...`);
    
    let successCount = 0;
    let fallbackCount = 0;
    let errorCount = 0;
    
    for (let i = 0; i < restaurants.length; i++) {
      const restaurant = restaurants[i];
      console.log(`\n[${i+1}/${restaurants.length}] ${restaurant.name} 처리 중...`);
      
      try {
        // 1단계: Google Places에서 장소 검색
        const place = await searchGooglePlace(
          restaurant.name, 
          restaurant.location.coordinates[1], // lat
          restaurant.location.coordinates[0]  // lng
        );
        
        let imageUrls = [];
        
        if (place && place.place_id) {
          // 2단계: 장소 상세 정보에서 사진 가져오기
          imageUrls = await getGooglePlacePhotos(place.place_id);
        }
        
        if (imageUrls.length > 0) {
          // 구글에서 실제 사진을 찾은 경우
          restaurant.images = imageUrls;
          successCount++;
          console.log(`✅ ${restaurant.name}: ${imageUrls.length}개 실제 사진 적용`);
        } else {
          // 실제 사진이 없으면 카테고리별 기본 이미지 사용
          restaurant.images = getFallbackImage(restaurant);
          fallbackCount++;
          console.log(`📷 ${restaurant.name}: 카테고리별 기본 이미지 사용`);
        }
        
        await restaurant.save();
        
        // API 요청 제한을 위한 딜레이 (분당 300요청 제한)
        await new Promise(resolve => setTimeout(resolve, 250)); // 0.25초 대기
        
      } catch (error) {
        console.error(`❌ ${restaurant.name} 처리 오류:`, error.message);
        
        // 오류 발생 시 기본 이미지라도 설정
        restaurant.images = getFallbackImage(restaurant);
        await restaurant.save();
        errorCount++;
      }
    }
    
    console.log('\n=== 업데이트 완료 ===');
    console.log(`✅ 실제 사진: ${successCount}개`);
    console.log(`📷 기본 이미지: ${fallbackCount}개`);
    console.log(`❌ 오류: ${errorCount}개`);
    console.log(`📊 실제 사진 성공률: ${((successCount / restaurants.length) * 100).toFixed(1)}%`);
    
    // 결과 샘플 확인
    const sampleRestaurants = await Restaurant.find({}).limit(5);
    console.log('\n=== 샘플 결과 ===');
    sampleRestaurants.forEach(r => {
      const isGooglePhoto = r.images[0].includes('googleapis.com');
      console.log(`${r.name}: ${isGooglePhoto ? '🌍 구글 사진' : '📷 기본 이미지'}`);
    });
    
    mongoose.connection.close();
    
  } catch (error) {
    console.error('업데이트 중 오류:', error);
    mongoose.connection.close();
  }
}

// API 키 설정 가이드
if (require.main === module) {
  if (!GOOGLE_API_KEY || GOOGLE_API_KEY === 'your-google-places-api-key') {
    console.log('\n🔑 Google Places API 키 설정이 필요합니다!');
    console.log('\n설정 방법:');
    console.log('1. https://console.cloud.google.com/ 접속');
    console.log('2. 새 프로젝트 생성 또는 기존 프로젝트 선택');
    console.log('3. "APIs & Services" > "Library" 이동');
    console.log('4. "Places API" 검색하고 활성화');
    console.log('5. "APIs & Services" > "Credentials" 이동');
    console.log('6. "Create Credentials" > "API Key" 선택');
    console.log('7. 생성된 API 키를 이 파일의 GOOGLE_API_KEY에 설정');
    console.log('\n💰 비용: 월 $200 크레딧으로 충분히 무료 사용 가능!');
    console.log('\n설정 완료 후 다시 실행하세요: node scripts/update-with-google-places.js');
  } else {
    updateWithGooglePlaces();
  }
}

module.exports = { updateWithGooglePlaces };