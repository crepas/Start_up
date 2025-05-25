const axios = require('axios');
require('dotenv').config();
const mongoose = require('mongoose');
const Restaurant = require('../models/Restaurant');
const connectDB = require('../config/db');

// 카카오 API 키
const KAKAO_API_KEY = process.env.KAKAO_API_KEY;

// 데이터베이스 연결
connectDB();

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
  
  // 세부 카테고리 분류
  if (categoryLower.includes('치킨')) return ['치킨'];
  if (categoryLower.includes('피자')) return ['피자'];
  if (categoryLower.includes('햄버거')) return ['햄버거', '패스트푸드'];
  if (categoryLower.includes('족발') || categoryLower.includes('보쌈')) return ['족발/보쌈'];
  if (categoryLower.includes('찌개') || categoryLower.includes('전골')) return ['찌개/전골'];
  
  return ['기타'];
}

// 카테고리에 따른 가격대 예상 (임의 설정)
function getPriceRangeFromCategory(categoryName) {
  const categoryLower = categoryName.toLowerCase();
  
  if (categoryLower.includes('고급') || categoryLower.includes('레스토랑') || 
      categoryLower.includes('스테이크') || categoryLower.includes('초밥')) {
    return '고가';
  }
  
  if (categoryLower.includes('패스트푸드') || categoryLower.includes('분식') || 
      categoryLower.includes('치킨') || categoryLower.includes('떡볶이')) {
    return '저렴';
  }
  
  return '중간';
}

// 카카오 로컬 API에서 음식점 데이터 가져오기
async function fetchRestaurantsFromKakao(keyword, x, y, radius, page = 1) {
  try {
    const response = await axios.get('https://dapi.kakao.com/v2/local/search/keyword.json', {
      headers: {
        Authorization: `KakaoAK ${KAKAO_API_KEY}`
      },
      params: {
        query: keyword,
        category_group_code: 'FD6', // 음식점 카테고리
        x: x, // 경도
        y: y, // 위도
        radius: radius, // 반경(미터)
        size: 45, // 최대 결과 수
        page: page
      }
    });
    
    return response.data;
  } catch (error) {
    console.error('카카오 API 호출 오류:', error.response ? error.response.data : error.message);
    throw error;
  }
}

// MongoDB에 음식점 저장하기
async function saveRestaurantToMongoDB(place) {
  try {
    // 이미 존재하는지 확인
    const existingRestaurant = await Restaurant.findOne({ kakaoId: place.id });
    
    if (existingRestaurant) {
      console.log(`음식점이 이미 존재합니다: ${place.place_name}`);
      return existingRestaurant;
    }
    
    // 음식 유형과 가격대 설정
    const foodTypes = getFoodTypesFromCategory(place.category_name);
    const priceRange = getPriceRangeFromCategory(place.category_name);
    
    // 새 음식점 데이터 생성
    const newRestaurant = new Restaurant({
      kakaoId: place.id,
      name: place.place_name,
      address: place.address_name,
      roadAddress: place.road_address_name,
      location: {
        type: 'Point',
        coordinates: [parseFloat(place.x), parseFloat(place.y)]
      },
      categoryGroupCode: place.category_group_code,
      categoryGroupName: place.category_group_name,
      categoryName: place.category_name,
      foodTypes: foodTypes,
      phone: place.phone,
      placeUrl: place.place_url,
      priceRange: priceRange,
      rating: 0,
      likes: 0,
      reviews: [],
      images: []
    });
    
    await newRestaurant.save();
    console.log(`새 음식점 저장됨: ${place.place_name}`);
    return newRestaurant;
  } catch (error) {
    console.error(`음식점 저장 오류 (${place.place_name}):`, error);
    return null;
  }
}

// 전체 데이터 가져오기 및 저장
async function importRestaurants() {
  try {
    console.log('음식점 데이터 가져오기 시작...');
    
    // 인천 용현동 좌표
    const x = '126.6503';
    const y = '37.4512';
    const radius = 2000; // 2km
    
    // 여러 키워드로 검색하여 다양한 음식점 데이터 확보
    const keywords = ['맛집', '음식점', '식당', '카페'];
    
    let totalSaved = 0;
    
    for (const keyword of keywords) {
      let page = 1;
      let isEnd = false;
      
      while (!isEnd && page <= 5) { // 최대 5페이지까지만
        console.log(`'${keyword}' 검색 - 페이지 ${page} 데이터 가져오는 중...`);
        
        const data = await fetchRestaurantsFromKakao(keyword, x, y, radius, page);
        const places = data.documents;
        
        console.log(`${places.length}개의 장소 데이터를 찾았습니다.`);
        
        // 각 음식점 데이터 저장
        for (const place of places) {
          if (place.category_group_code === 'FD6' || place.category_group_code === 'CE7') {
            const saved = await saveRestaurantToMongoDB(place);
            if (saved) totalSaved++;
          }
        }
        
        isEnd = data.meta.is_end;
        page++;
        
        // API 과부하 방지를 위한 지연
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }
    
    console.log(`총 ${totalSaved}개의 음식점 데이터를 저장했습니다.`);
    mongoose.connection.close();
    console.log('데이터베이스 연결 종료');
    
  } catch (error) {
    console.error('데이터 가져오기 오류:', error);
    mongoose.connection.close();
  }
}

// 스크립트 실행
importRestaurants();