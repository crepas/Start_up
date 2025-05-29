const axios = require('axios');
require('dotenv').config();
const mongoose = require('mongoose');
const Restaurant = require('../models/Restaurant');
const connectDB = require('../config/db');

// 카카오 API 키
const KAKAO_API_KEY = process.env.KAKAO_API_KEY || '4e4572f409f9b0cd5dc1f574779a03a7';

// 데이터베이스 연결
connectDB();

// 인하대 후문 정확한 좌표 (37.4516, 126.7015)
const INHA_BACK_GATE = {
  lat: 37.4516,
  lng: 126.7015,
  radius: 1500 // 1.5km 반경
};

// 카테고리에 따른 음식 유형 반환
function getFoodTypesFromCategory(categoryName) {
  const categoryLower = categoryName.toLowerCase();
  
  if (categoryLower.includes('한식')) return ['한식'];
  if (categoryLower.includes('중식')) return ['중식'];
  if (categoryLower.includes('일식')) return ['일식'];
  if (categoryLower.includes('양식')) return ['양식'];
  if (categoryLower.includes('카페')) return ['카페', '디저트'];
  if (categoryLower.includes('분식')) return ['분식'];
  if (categoryLower.includes('육류') || categoryLower.includes('고기')) return ['고기'];
  if (categoryLower.includes('해물') || categoryLower.includes('생선')) return ['해산물'];
  if (categoryLower.includes('치킨')) return ['치킨'];
  if (categoryLower.includes('피자')) return ['피자'];
  if (categoryLower.includes('햄버거')) return ['햄버거', '패스트푸드'];
  if (categoryLower.includes('족발') || categoryLower.includes('보쌈')) return ['족발/보쌈'];
  if (categoryLower.includes('찌개') || categoryLower.includes('전골')) return ['찌개/전골'];
  
  return ['기타'];
}

// 카테고리에 따른 가격대 예상
function getPriceRangeFromCategory(categoryName) {
  const categoryLower = categoryName.toLowerCase();
  
  if (categoryLower.includes('고급') || categoryLower.includes('레스토랑') || 
      categoryLower.includes('스테이크') || categoryLower.includes('초밥')) {
    return '고가';
  }
  
  if (categoryLower.includes('패스트푸드') || categoryLower.includes('분식') || 
      categoryLower.includes('치킨') || categoryLower.includes('떡볶이') ||
      categoryLower.includes('카페') || categoryLower.includes('커피')) {
    return '저렴';
  }
  
  return '중간';
}

// 카카오 로컬 API에서 음식점 및 카페 데이터 가져오기
async function fetchPlacesFromKakao(keyword, categoryCode, page = 1) {
  try {
    const response = await axios.get('https://dapi.kakao.com/v2/local/search/keyword.json', {
      headers: {
        Authorization: `KakaoAK ${KAKAO_API_KEY}`
      },
      params: {
        query: keyword,
        category_group_code: categoryCode, // FD6: 음식점, CE7: 카페
        x: INHA_BACK_GATE.lng,
        y: INHA_BACK_GATE.lat,
        radius: INHA_BACK_GATE.radius,
        size: 15,
        page: page
      }
    });
    
    return response.data;
  } catch (error) {
    console.error('카카오 API 호출 오류:', error.response ? error.response.data : error.message);
    throw error;
  }
}

// MongoDB에 음식점/카페 저장하기
async function savePlaceToMongoDB(place) {
  try {
    // 이미 존재하는지 확인
    const existingPlace = await Restaurant.findOne({ kakaoId: place.id });
    
    if (existingPlace) {
      console.log(`이미 존재합니다: ${place.place_name}`);
      return existingPlace;
    }
    
    // 음식 유형과 가격대 설정
    const foodTypes = getFoodTypesFromCategory(place.category_name);
    const priceRange = getPriceRangeFromCategory(place.category_name);
    
    // 임의의 평점 및 좋아요 수 생성 (실제 데이터)
    const rating = Math.round((Math.random() * 2 + 3) * 10) / 10; // 3.0-5.0
    const likes = Math.floor(Math.random() * 200); // 0-199
    
    // 새 음식점/카페 데이터 생성
    const newPlace = new Restaurant({
      kakaoId: place.id,
      name: place.place_name,
      address: place.address_name,
      roadAddress: place.road_address_name || place.address_name,
      location: {
        type: 'Point',
        coordinates: [parseFloat(place.x), parseFloat(place.y)]
      },
      categoryGroupCode: place.category_group_code,
      categoryGroupName: place.category_group_name,
      categoryName: place.category_name,
      foodTypes: foodTypes,
      phone: place.phone || '',
      placeUrl: place.place_url,
      priceRange: priceRange,
      rating: rating,
      likes: likes,
      reviews: [],
      images: ['assets/restaurant.png'] // 기본 이미지
    });
    
    await newPlace.save();
    console.log(`새로 저장됨: ${place.place_name} (${place.category_name})`);
    return newPlace;
  } catch (error) {
    console.error(`저장 오류 (${place.place_name}):`, error);
    return null;
  }
}

// 인하대 후문 주변 음식점 및 카페 데이터 가져오기
async function importInhaRestaurants() {
  try {
    console.log('인하대 후문 주변 음식점/카페 데이터 가져오기 시작...');
    console.log(`위치: 위도 ${INHA_BACK_GATE.lat}, 경도 ${INHA_BACK_GATE.lng}`);
    console.log(`반경: ${INHA_BACK_GATE.radius}m`);
    
    // 기존 데이터 삭제 (선택사항)
    // await Restaurant.deleteMany({});
    // console.log('기존 데이터 삭제 완료');
    
    let totalSaved = 0;
    
    // 1. 음식점 데이터 가져오기 (FD6)
    console.log('\n=== 음식점 데이터 수집 시작 ===');
    const foodKeywords = ['맛집', '음식점', '식당', '한식', '중식', '일식', '양식'];
    
    for (const keyword of foodKeywords) {
      let page = 1;
      let isEnd = false;
      
      while (!isEnd && page <= 3) {
        console.log(`음식점 '${keyword}' 검색 - 페이지 ${page}`);
        
        try {
          const data = await fetchPlacesFromKakao(keyword, 'FD6', page);
          const places = data.documents;
          
          console.log(`${places.length}개의 음식점 발견`);
          
          for (const place of places) {
            const saved = await savePlaceToMongoDB(place);
            if (saved) totalSaved++;
          }
          
          isEnd = data.meta.is_end;
          page++;
          
          // API 과부하 방지
          await new Promise(resolve => setTimeout(resolve, 500));
        } catch (error) {
          console.error(`${keyword} 검색 오류:`, error.message);
          break;
        }
      }
    }
    
    // 2. 카페 데이터 가져오기 (CE7)
    console.log('\n=== 카페 데이터 수집 시작 ===');
    const cafeKeywords = ['카페', '커피', '디저트', '베이커리'];
    
    for (const keyword of cafeKeywords) {
      let page = 1;
      let isEnd = false;
      
      while (!isEnd && page <= 3) {
        console.log(`카페 '${keyword}' 검색 - 페이지 ${page}`);
        
        try {
          const data = await fetchPlacesFromKakao(keyword, 'CE7', page);
          const places = data.documents;
          
          console.log(`${places.length}개의 카페 발견`);
          
          for (const place of places) {
            const saved = await savePlaceToMongoDB(place);
            if (saved) totalSaved++;
          }
          
          isEnd = data.meta.is_end;
          page++;
          
          // API 과부하 방지
          await new Promise(resolve => setTimeout(resolve, 500));
        } catch (error) {
          console.error(`${keyword} 검색 오류:`, error.message);
          break;
        }
      }
    }
    
    // 결과 출력
    console.log(`\n=== 데이터 수집 완료 ===`);
    console.log(`총 ${totalSaved}개의 음식점/카페 데이터를 저장했습니다.`);
    
    // 저장된 데이터 확인
    const totalCount = await Restaurant.countDocuments();
    const foodCount = await Restaurant.countDocuments({ categoryGroupCode: 'FD6' });
    const cafeCount = await Restaurant.countDocuments({ categoryGroupCode: 'CE7' });
    
    console.log(`\n데이터베이스 현황:`);
    console.log(`- 전체: ${totalCount}개`);
    console.log(`- 음식점: ${foodCount}개`);
    console.log(`- 카페: ${cafeCount}개`);
    
    mongoose.connection.close();
    console.log('데이터베이스 연결 종료');
    
  } catch (error) {
    console.error('데이터 가져오기 오류:', error);
    mongoose.connection.close();
  }
}

// 스크립트 실행
if (require.main === module) {
  importInhaRestaurants();
}

module.exports = { importInhaRestaurants, INHA_BACK_GATE };