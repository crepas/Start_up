const express = require('express');
const router = express.Router();
const Restaurant = require('../models/Restaurant');
const { isAuthenticated } = require('../middlewares/auth');
const axios = require('axios');

// 모든 음식점 목록 가져오기 (하이브리드 방식)
router.get('/restaurants', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10,
      sort = 'rating',
      category,
      foodType,
      priceRange,
      query,
      lat,
      lng,
      radius = 2000
    } = req.query;
    
    console.log('API 호출 파라미터:', { lat, lng, radius, sort });
    
    let restaurants = [];
    let total = 0;
    let source = 'database';
    
    if (lat && lng) {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      const radiusInMeters = parseInt(radius);
      
      // 1단계: MongoDB에서 먼저 검색
      const queryObj = {};
      queryObj.location = {
        $geoWithin: {
          $centerSphere: [[longitude, latitude], radiusInMeters / 6378100]
        }
      };
      
      // 필터 조건 추가
      if (category) {
        queryObj.categoryName = { $regex: category, $options: 'i' };
      }
      if (foodType) {
        queryObj.foodTypes = { $in: [foodType] };
      }
      if (priceRange) {
        queryObj.priceRange = priceRange;
      }
      if (query) {
        queryObj.$or = [
          { name: { $regex: query, $options: 'i' } },
          { address: { $regex: query, $options: 'i' } },
          { categoryName: { $regex: query, $options: 'i' } }
        ];
      }
      
      const dbRestaurants = await Restaurant.find(queryObj).limit(50);
      console.log(`DB에서 찾은 음식점: ${dbRestaurants.length}개`);
      
      // 2단계: DB에 데이터가 부족하면 실시간 API 호출
      if (dbRestaurants.length < 5) {
        console.log('DB 데이터 부족, 카카오 API 호출...');
        
        try {
          let allKakaoData = [];
          const keywords = ['맛집', '음식점']; // 2개 키워드
          const maxPagesPerKeyword = 2; // 각 키워드당 2페이지
          
          for (const keyword of keywords) {
            for (let page = 1; page <= maxPagesPerKeyword; page++) {
              try {
                const kakaoResponse = await axios.get('https://dapi.kakao.com/v2/local/search/keyword.json', {
                  headers: {
                    Authorization: `KakaoAK ${process.env.KAKAO_API_KEY}`
                  },
                  params: {
                    query: keyword,
                    category_group_code: 'FD6',
                    x: longitude,
                    y: latitude,
                    radius: radiusInMeters,
                    size: 15,
                    page: page,
                    sort: 'distance'
                  }
                });
                
                allKakaoData.push(...kakaoResponse.data.documents);
                
                if (kakaoResponse.data.meta.is_end) {
                  break;
                }
                
                // API 과부하 방지
                await new Promise(resolve => setTimeout(resolve, 100));
                
              } catch (pageError) {
                console.error(`${keyword} 페이지 ${page} 호출 오류:`, pageError.message);
                break;
              }
            }
          }
          
          // 중복 제거 (같은 kakao ID)
          const uniqueData = [];
          const seenIds = new Set();
          
          for (const place of allKakaoData) {
            if (!seenIds.has(place.id)) {
              uniqueData.push(place);
              seenIds.add(place.id);
            }
          }
          
          console.log(`카카오 API에서 가져온 음식점: ${uniqueData.length}개 (중복 제거 후)`);
          
          // 카카오 데이터를 우리 형식으로 변환
          const realtimeRestaurants = uniqueData.map(place => ({
            id: place.id,
            name: place.place_name,
            address: place.address_name,
            roadAddress: place.road_address_name || place.address_name,
            lat: parseFloat(place.y),
            lng: parseFloat(place.x),
            categoryName: place.category_name,
            foodTypes: getFoodTypesFromCategory(place.category_name),
            phone: place.phone || '',
            placeUrl: place.place_url,
            priceRange: getPriceRangeFromCategory(place.category_name),
            rating: Math.random() * 2 + 3, // 3.0-5.0 랜덤
            likes: Math.floor(Math.random() * 100),
            reviews: [],
            images: ['assets/restaurant.png'],
            isLiked: false,
            isAd: false,
            isOpen: true,
            hasParking: Math.random() > 0.5,
            hasDelivery: Math.random() > 0.3,
            hasReservation: false,
            hasWifi: Math.random() > 0.4,
            isPetFriendly: false,
            reviewCount: Math.floor(Math.random() * 20),
            createdAt: new Date(),
            distance: place.distance,
            source: 'realtime'
          }));
          
          // DB 데이터와 실시간 데이터 합치기
          restaurants = [
            ...dbRestaurants.map(r => ({ ...r.toObject(), source: 'database' })),
            ...realtimeRestaurants
          ];
          
          source = 'hybrid';
          
        } catch (kakaoError) {
          console.error('카카오 API 오류:', kakaoError.message);
          restaurants = dbRestaurants.map(r => ({ ...r.toObject(), source: 'database' }));
        }
      } else {
        // DB에 충분한 데이터가 있으면 DB만 사용 + 거리순 정렬 처리
        if (sort === 'distance') {
          try {
            // 거리순 정렬을 위한 aggregation
            const pipeline = [
              {
                $geoNear: {
                  near: {
                    type: "Point",
                    coordinates: [longitude, latitude]
                  },
                  distanceField: "calculatedDistance",
                  maxDistance: radiusInMeters,
                  spherical: true,
                  query: queryObj
                }
              }
            ];
            
            restaurants = await Restaurant.aggregate(pipeline);
            restaurants = restaurants.map(r => ({ ...r, source: 'database' }));
          } catch (geoError) {
            console.error('거리순 정렬 오류:', geoError.message);
            restaurants = dbRestaurants.map(r => ({ ...r.toObject(), source: 'database' }));
          }
        } else {
          restaurants = dbRestaurants.map(r => ({ ...r.toObject(), source: 'database' }));
        }
      }
      
      // 3단계: 추가 필터링 (실시간 데이터에 대해)
      if (category) {
        restaurants = restaurants.filter(r => 
          r.categoryName && r.categoryName.toLowerCase().includes(category.toLowerCase())
        );
      }
      
      if (foodType) {
        restaurants = restaurants.filter(r => 
          r.foodTypes && r.foodTypes.includes(foodType)
        );
      }
      
      if (priceRange) {
        restaurants = restaurants.filter(r => r.priceRange === priceRange);
      }
      
      if (query) {
        restaurants = restaurants.filter(r => 
          (r.name && r.name.toLowerCase().includes(query.toLowerCase())) ||
          (r.address && r.address.toLowerCase().includes(query.toLowerCase()))
        );
      }
      
      // 4단계: 정렬
      if (sort === 'distance' && restaurants[0]?.distance !== undefined) {
        restaurants.sort((a, b) => (a.distance || a.calculatedDistance || 0) - (b.distance || b.calculatedDistance || 0));
      } else if (sort === 'rating') {
        restaurants.sort((a, b) => (b.rating || 0) - (a.rating || 0));
      } else if (sort === 'likes') {
        restaurants.sort((a, b) => (b.likes || 0) - (a.likes || 0));
      }
      
      // 5단계: 페이지네이션
      total = restaurants.length;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      restaurants = restaurants.slice(skip, skip + parseInt(limit));
      
    } else {
      // 위치 정보 없으면 기존 방식대로
      const queryObj = {};
      
      if (category) {
        queryObj.categoryName = { $regex: category, $options: 'i' };
      }
      if (foodType) {
        queryObj.foodTypes = { $in: [foodType] };
      }
      if (priceRange) {
        queryObj.priceRange = priceRange;
      }
      if (query) {
        queryObj.$or = [
          { name: { $regex: query, $options: 'i' } },
          { address: { $regex: query, $options: 'i' } },
          { categoryName: { $regex: query, $options: 'i' } }
        ];
      }
      
      let sortOption = {};
      if (sort === 'rating') {
        sortOption = { rating: -1 };
      } else if (sort === 'likes') {
        sortOption = { likes: -1 };
      } else {
        sortOption = { name: 1 };
      }
      
      restaurants = await Restaurant.find(queryObj)
        .sort(sortOption)
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit));
      
      total = await Restaurant.countDocuments(queryObj);
      restaurants = restaurants.map(r => ({ ...r.toObject(), source: 'database' }));
    }
    
    console.log(`최종 반환: ${restaurants.length}개 (${source})`);
    
    res.status(200).json({
      restaurants,
      totalPages: Math.ceil(total / parseInt(limit)),
      currentPage: parseInt(page),
      total,
      source,
      location: lat && lng ? { lat: parseFloat(lat), lng: parseFloat(lng) } : null
    });
    
  } catch (error) {
    console.error('음식점 조회 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 특정 음식점 상세 정보 가져오기
router.get('/restaurants/:id', async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    
    if (!restaurant) {
      return res.status(404).json({ message: '음식점을 찾을 수 없습니다.' });
    }
    
    res.status(200).json({ restaurant });
  } catch (error) {
    console.error('음식점 상세 조회 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 리뷰 작성하기 (인증 필요)
router.post('/restaurants/:id/reviews', isAuthenticated, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    
    if (!rating || !comment) {
      return res.status(400).json({ message: '평점과 리뷰 내용은 필수입니다.' });
    }
    
    const restaurant = await Restaurant.findById(req.params.id);
    
    if (!restaurant) {
      return res.status(404).json({ message: '음식점을 찾을 수 없습니다.' });
    }
    
    // 이미 리뷰를 작성했는지 확인
    const existingReview = restaurant.reviews.find(
      review => review.userId && review.userId.toString() === req.session.user.id
    );
    
    if (existingReview) {
      return res.status(400).json({ message: '이미 리뷰를 작성했습니다.' });
    }
    
    // 새 리뷰 추가
    restaurant.reviews.push({
      userId: req.session.user.id,
      username: req.session.user.username,
      rating: parseFloat(rating),
      comment,
      date: new Date()
    });
    
    // 평점 업데이트
    const totalRating = restaurant.reviews.reduce((sum, review) => sum + review.rating, 0);
    restaurant.rating = parseFloat((totalRating / restaurant.reviews.length).toFixed(1));
    
    await restaurant.save();
    
    res.status(201).json({
      message: '리뷰가 등록되었습니다.',
      restaurant
    });
  } catch (error) {
    console.error('리뷰 작성 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 음식점 좋아요 추가/취소 (인증 필요)
router.post('/restaurants/:id/like', isAuthenticated, async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    
    if (!restaurant) {
      return res.status(404).json({ message: '음식점을 찾을 수 없습니다.' });
    }
    
    const User = require('../models/User');
    const user = await User.findById(req.session.user.id);
    
    if (!user.likedRestaurants) {
      user.likedRestaurants = [];
    }
    
    const alreadyLiked = user.likedRestaurants.includes(req.params.id);
    
    if (alreadyLiked) {
      user.likedRestaurants = user.likedRestaurants.filter(id => id.toString() !== req.params.id);
      restaurant.likes = Math.max(0, restaurant.likes - 1);
    } else {
      user.likedRestaurants.push(req.params.id);
      restaurant.likes += 1;
    }
    
    await restaurant.save();
    await user.save();
    
    res.status(200).json({
      message: alreadyLiked ? '좋아요가 취소되었습니다.' : '좋아요가 추가되었습니다.',
      likes: restaurant.likes,
      isLiked: !alreadyLiked
    });
  } catch (error) {
    console.error('좋아요 토글 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 카테고리별 음식점 탐색
router.get('/restaurants/categories/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const { limit = 10 } = req.query;
    
    const restaurants = await Restaurant.find({
      categoryName: { $regex: category, $options: 'i' }
    })
    .sort({ rating: -1 })
    .limit(parseInt(limit));
    
    res.status(200).json({ restaurants });
  } catch (error) {
    console.error('카테고리별 음식점 조회 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 다음 행선지 추천
router.get('/restaurants/recommend/next', isAuthenticated, async (req, res) => {
  try {
    const { currentId, lat, lng } = req.query;
    
    if (!currentId && (!lat || !lng)) {
      return res.status(400).json({ message: '현재 음식점 ID 또는 위치 정보가 필요합니다.' });
    }
    
    let currentRestaurant;
    let currentCategory;
    
    if (currentId) {
      currentRestaurant = await Restaurant.findById(currentId);
      if (!currentRestaurant) {
        return res.status(404).json({ message: '현재 음식점을 찾을 수 없습니다.' });
      }
      currentCategory = currentRestaurant.categoryName.split(' > ')[0];
    }
    
    const User = require('../models/User');
    const user = await User.findById(req.session.user.id);
    
    const queryObj = {};
    
    if (currentCategory) {
      if (currentCategory.includes('카페') || currentCategory.includes('디저트')) {
        queryObj.categoryName = { $not: { $regex: '카페|디저트', $options: 'i' } };
      } else {
        queryObj.categoryName = { $regex: '카페|디저트', $options: 'i' };
      }
    }
    
    const coordinates = currentRestaurant ? 
      currentRestaurant.location.coordinates : 
      [parseFloat(lng), parseFloat(lat)];
    
    queryObj.location = {
      $geoWithin: {
        $centerSphere: [coordinates, 1000 / 6378100]
      }
    };
    
    if (currentId) {
      queryObj._id = { $ne: currentId };
    }
    
    let recommendations = [];
    
    if (user && user.preferences && user.preferences.foodTypes && user.preferences.foodTypes.length > 0) {
      const preferredQuery = { ...queryObj };
      preferredQuery.foodTypes = { $in: user.preferences.foodTypes };
      
      recommendations = await Restaurant.find(preferredQuery)
        .sort({ rating: -1 })
        .limit(3);
    }
    
    if (recommendations.length < 3) {
      const generalRecommendations = await Restaurant.find(queryObj)
        .sort({ rating: -1 })
        .limit(5 - recommendations.length);
      
      recommendations = [...recommendations, ...generalRecommendations];
    }
    
    res.status(200).json({ recommendations });
  } catch (error) {
    console.error('추천 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 헬퍼 함수들
function getFoodTypesFromCategory(categoryName) {
  const categoryLower = categoryName.toLowerCase();
  if (categoryLower.includes('한식')) return ['한식'];
  if (categoryLower.includes('중식')) return ['중식'];
  if (categoryLower.includes('일식')) return ['일식'];
  if (categoryLower.includes('양식')) return ['양식'];
  if (categoryLower.includes('카페')) return ['카페'];
  if (categoryLower.includes('치킨')) return ['치킨'];
  if (categoryLower.includes('피자')) return ['피자'];
  if (categoryLower.includes('족발')) return ['족발'];
  return ['기타'];
}

function getPriceRangeFromCategory(categoryName) {
  const categoryLower = categoryName.toLowerCase();
  if (categoryLower.includes('고급') || categoryLower.includes('레스토랑')) return '고가';
  if (categoryLower.includes('분식') || categoryLower.includes('패스트푸드')) return '저렴';
  return '중간';
}

module.exports = router;