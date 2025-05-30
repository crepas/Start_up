// import-inha-restaurants.js 수정된 버전

const axios = require('axios');
require('dotenv').config();
const mongoose = require('mongoose');
const Restaurant = require('../models/Restaurant');
const connectDB = require('../config/db');

// 카카오 API 키
const KAKAO_API_KEY = process.env.KAKAO_API_KEY || '4e4572f409f9b0cd5dc1f574779a03a7';

// 데이터베이스 연결
connectDB();

// 인하대 후문 정확한 좌표
const INHA_BACK_GATE = {
  lat: 37.45169,
  lng: 126.65464,
  radius: 2000 // 2km 반경
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

// 카카오 장소 상세 정보에서 이미지 가져오기
async function getPlaceImages(placeId) {
  try {
    console.log(`장소 ID ${placeId}의 이미지 가져오는 중...`);
    
    // 카카오 장소 상세 API 호출
    const response = await axios.get(`https://place.map.kakao.com/main/v/${placeId}`, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'ko-KR,ko;q=0.8,en-US;q=0.5,en;q=0.3',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1'
      },
      timeout: 10000
    });

    // HTML에서 이미지 URL 추출 (정규식 사용)
    const html = response.data;
    const imageUrls = [];
    
    // 다양한 패턴으로 이미지 URL 찾기
    const patterns = [
      /https:\/\/t1\.daumcdn\.net\/place\/[^"'\s)]+/g,
      /https:\/\/img1\.daumcdn\.net\/thumb\/[^"'\s)]+/g,
      /https:\/\/t1\.kakaocdn\.net\/[^"'\s)]+/g
    ];
    
    patterns.forEach(pattern => {
      const matches = html.match(pattern);
      if (matches) {
        matches.forEach(match => {
          // URL 정리 (쿼리 파라미터 제거)
          const cleanUrl = match.split('?')[0];
          if (!imageUrls.includes(cleanUrl)) {
            imageUrls.push(cleanUrl);
          }
        });
      }
    });
    
    console.log(`장소 ID ${placeId}에서 ${imageUrls.length}개의 이미지 발견`);
    return imageUrls.slice(0, 5); // 최대 5개만 반환
    
  } catch (error) {
    console.log(`장소 ID ${placeId} 이미지 가져오기 실패:`, error.message);
    return [];
  }
}

// 대체 이미지 URL 생성 (카카오 기본 이미지 사용)
function generateFallbackImages(categoryName, placeName) {
  const foodTypeImages = {
    '한식': 'https://t1.daumcdn.net/cfile/tistory/995EFF455C9F1E2518',
    '중식': 'https://t1.daumcdn.net/cfile/tistory/998C67355C9F1E2606',
    '일식': 'https://t1.daumcdn.net/cfile/tistory/997F46355C9F1E2702',
    '양식': 'https://t1.daumcdn.net/cfile/tistory/996F2E355C9F1E2811',
    '카페': 'https://t1.daumcdn.net/cfile/tistory/993A50355C9F1E2904',
    '치킨': 'https://t1.daumcdn.net/cfile/tistory/991234355C9F1E3005',
    '피자': 'https://t1.daumcdn.net/cfile/tistory/99E34C355C9F1E3118',
    '족발': 'https://t1.daumcdn.net/cfile/tistory/99B567355C9F1E3201'
  };
  
  // 카테고리에 맞는 기본 이미지 찾기
  for (const [type, imageUrl] of Object.entries(foodTypeImages)) {
    if (categoryName.includes(type)) {
      return [imageUrl];
    }
  }
  
  // 기본 음식점 이미지
  return ['https://t1.daumcdn.net/cfile/tistory/992B3E355C9F1E3312'];
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

// MongoDB에 음식점/카페 저장하기 (이미지 포함)
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
    
    // 이미지 가져오기 시도
    console.log(`${place.place_name}의 이미지 검색 중...`);
    let imageUrls = await getPlaceImages(place.id);
    
    // 이미지를 찾지 못한 경우 카테고리별 기본 이미지 사용
    if (imageUrls.length === 0) {
      console.log(`${place.place_name}: 실제 이미지를 찾지 못해 기본 이미지 사용`);
      imageUrls = generateFallbackImages(place.category_name, place.place_name);
    } else {
      console.log(`${place.place_name}: ${imageUrls.length}개의 실제 이미지 발견`);
    }
    
    // 임의의 평점 및 좋아요 수 생성
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
      images: imageUrls // 실제 카카오에서 가져온 이미지들
    });
    
    await newPlace.save();
    console.log(`새로 저장됨: ${place.place_name} (이미지 ${imageUrls.length}개)`);
    return newPlace;
  } catch (error) {
    console.error(`저장 오류 (${place.place_name}):`, error);
    return null;
  }
}

// 기존 음식점들의 이미지 업데이트
async function updateExistingRestaurantImages() {
  try {
    console.log('기존 음식점들의 이미지 업데이트 시작...');
    
    // 기본 이미지만 있는 음식점들 찾기
    const restaurantsToUpdate = await Restaurant.find({
      $or: [
        { images: { $size: 0 } },
        { images: ['assets/restaurant.png'] },
        { images: { $exists: false } }
      ]
    });
    
    console.log(`업데이트할 음식점 수: ${restaurantsToUpdate.length}개`);
    
    for (const restaurant of restaurantsToUpdate) {
      console.log(`${restaurant.name} 이미지 업데이트 중...`);
      
      if (restaurant.kakaoId) {
        // 카카오 ID가 있으면 실제 이미지 가져오기 시도
        const imageUrls = await getPlaceImages(restaurant.kakaoId);
        
        if (imageUrls.length > 0) {
          restaurant.images = imageUrls;
          console.log(`${restaurant.name}: ${imageUrls.length}개 실제 이미지 추가`);
        } else {
          // 실제 이미지가 없으면 카테고리별 기본 이미지
          restaurant.images = generateFallbackImages(restaurant.categoryName, restaurant.name);
          console.log(`${restaurant.name}: 카테고리별 기본 이미지 사용`);
        }
        
        await restaurant.save();
      } else {
        // 카카오 ID가 없으면 카테고리별 기본 이미지만 사용
        restaurant.images = generateFallbackImages(restaurant.categoryName, restaurant.name);
        await restaurant.save();
        console.log(`${restaurant.name}: 카테고리별 기본 이미지 사용 (카카오ID 없음)`);
      }
      
      // API 과부하 방지를 위한 딜레이
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    console.log('기존 음식점 이미지 업데이트 완료!');
  } catch (error) {
    console.error('기존 음식점 이미지 업데이트 오류:', error);
  }
}

// 인하대 후문 주변 음식점 및 카페 데이터 가져오기
async function importInhaRestaurants() {
  try {
    console.log('인하대 후문 주변 음식점/카페 데이터 가져오기 시작...');
    console.log(`위치: 위도 ${INHA_BACK_GATE.lat}, 경도 ${INHA_BACK_GATE.lng}`);
    console.log(`반경: ${INHA_BACK_GATE.radius}m`);
    
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
            
            // 이미지 가져오기 때문에 더 긴 딜레이
            await new Promise(resolve => setTimeout(resolve, 1500));
          }
          
          isEnd = data.meta.is_end;
          page++;
          
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
            
            // 이미지 가져오기 때문에 딜레이
            await new Promise(resolve => setTimeout(resolve, 1500));
          }
          
          isEnd = data.meta.is_end;
          page++;
          
        } catch (error) {
          console.error(`${keyword} 검색 오류:`, error.message);
          break;
        }
      }
    }
    
    // 3. 기존 음식점들의 이미지 업데이트
    console.log('\n=== 기존 음식점 이미지 업데이트 ===');
    await updateExistingRestaurantImages();
    
    // 결과 출력
    console.log(`\n=== 데이터 수집 완료 ===`);
    console.log(`총 ${totalSaved}개의 음식점/카페 데이터를 저장했습니다.`);
    
    // 저장된 데이터 확인
    const totalCount = await Restaurant.countDocuments();
    const foodCount = await Restaurant.countDocuments({ categoryGroupCode: 'FD6' });
    const cafeCount = await Restaurant.countDocuments({ categoryGroupCode: 'CE7' });
    const withRealImages = await Restaurant.countDocuments({ 
      images: { $not: { $regex: /^assets\/|^https:\/\/t1\.daumcdn\.net\/cfile/ } }
    });
    
    console.log(`\n데이터베이스 현황:`);
    console.log(`- 전체: ${totalCount}개`);
    console.log(`- 음식점: ${foodCount}개`);
    console.log(`- 카페: ${cafeCount}개`);
    console.log(`- 실제 이미지가 있는 곳: ${withRealImages}개`);
    
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

module.exports = { importInhaRestaurants, updateExistingRestaurantImages, INHA_BACK_GATE };