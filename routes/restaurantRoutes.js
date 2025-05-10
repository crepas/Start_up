const express = require('express');
const router = express.Router();
const Restaurant = require('../models/Restaurant');
const { isAuthenticated } = require('../middlewares/auth');

// 모든 음식점 목록 가져오기 (페이지네이션 포함)
router.get('/restaurants', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10,
      sort = 'rating', // 기본 정렬: 평점순
      category,
      foodType,
      priceRange,
      query,
      lat,
      lng,
      radius = 2000 // 기본 반경: 2km
    } = req.query;
    
    // 기본 쿼리 객체
    const queryObj = {};
    
    // 카테고리 필터
    if (category) {
      queryObj.categoryName = { $regex: category, $options: 'i' };
    }
    
    // 음식 유형 필터
    if (foodType) {
      queryObj.foodTypes = { $in: [foodType] };
    }
    
    // 가격대 필터
    if (priceRange) {
      queryObj.priceRange = priceRange;
    }
    
    // 검색어 필터
    if (query) {
      queryObj.$or = [
        { name: { $regex: query, $options: 'i' } },
        { address: { $regex: query, $options: 'i' } },
        { categoryName: { $regex: query, $options: 'i' } }
      ];
    }
    
    // 위치 기반 필터
    if (lat && lng) {
      queryObj.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius)
        }
      };
    }
    
    // 정렬 옵션
    let sortOption = {};
    if (sort === 'rating') {
      sortOption = { rating: -1 };
    } else if (sort === 'likes') {
      sortOption = { likes: -1 };
    } else if (sort === 'distance' && lat && lng) {
      // 거리 정렬은 위치 쿼리에서 자동으로 처리됨
      sortOption = {};
    } else {
      sortOption = { name: 1 }; // 기본: 이름순
    }
    
    // 페이지네이션 계산
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // 음식점 데이터 조회
    const restaurants = await Restaurant.find(queryObj)
      .sort(sortOption)
      .skip(skip)
      .limit(parseInt(limit));
    
    // 전체 개수 조회
    const total = await Restaurant.countDocuments(queryObj);
    
    res.status(200).json({
      restaurants,
      totalPages: Math.ceil(total / parseInt(limit)),
      currentPage: parseInt(page),
      total
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
    
    // User 모델을 가져와서 사용자의 좋아요 목록을 확인하고 업데이트하는 로직
    const User = require('../models/User');
    const user = await User.findById(req.session.user.id);
    
    // 사용자 모델에 likedRestaurants 필드가 없다면 추가
    if (!user.likedRestaurants) {
      user.likedRestaurants = [];
    }
    
    const alreadyLiked = user.likedRestaurants.includes(req.params.id);
    
    if (alreadyLiked) {
      // 좋아요 취소
      user.likedRestaurants = user.likedRestaurants.filter(id => id.toString() !== req.params.id);
      restaurant.likes = Math.max(0, restaurant.likes - 1);
    } else {
      // 좋아요 추가
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
    
    // 카테고리로 음식점 검색
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
    
    // 현재 음식점 정보 가져오기
    if (currentId) {
      currentRestaurant = await Restaurant.findById(currentId);
      if (!currentRestaurant) {
        return res.status(404).json({ message: '현재 음식점을 찾을 수 없습니다.' });
      }
      currentCategory = currentRestaurant.categoryName.split(' > ')[0];
    }
    
    // 사용자 선호도 가져오기
    const User = require('../models/User');
    const user = await User.findById(req.session.user.id);
    
    // 쿼리 객체 생성
    const queryObj = {};
    
    // 현재 카테고리와 다른 카테고리 추천
    if (currentCategory) {
      // 식사 후 카페, 카페 후 식사 패턴
      if (currentCategory.includes('카페') || currentCategory.includes('디저트')) {
        queryObj.categoryName = { $not: { $regex: '카페|디저트', $options: 'i' } };
      } else {
        queryObj.categoryName = { $regex: '카페|디저트', $options: 'i' };
      }
    }
    
    // 위치 기반 필터
    const coordinates = currentRestaurant ? 
      currentRestaurant.location.coordinates : 
      [parseFloat(lng), parseFloat(lat)];
    
    queryObj.location = {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates
        },
        $maxDistance: 1000 // 1km 이내
      }
    };
    
    // 현재 음식점은 제외
    if (currentId) {
      queryObj._id = { $ne: currentId };
    }
    
    // 사용자 선호도 반영
    let recommendations = [];
    
    if (user && user.preferences && user.preferences.foodTypes && user.preferences.foodTypes.length > 0) {
      // 사용자 선호 음식 유형으로 검색
      const preferredQuery = { ...queryObj };
      preferredQuery.foodTypes = { $in: user.preferences.foodTypes };
      
      // 선호도 기반 추천
      recommendations = await Restaurant.find(preferredQuery)
        .sort({ rating: -1 })
        .limit(3);
    }
    
    // 추천이 부족한 경우 일반 추천도 추가
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

module.exports = router;