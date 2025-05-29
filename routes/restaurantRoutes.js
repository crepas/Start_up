const express = require('express');
const router = express.Router();
const Restaurant = require('../models/Restaurant');
const { isAuthenticated } = require('../middlewares/auth');

// 인하대 후문 정확한 좌표
const INHA_BACK_GATE = {
  lat: 37.45169,
  lng: 126.65464,
  radius: 2000 // 2km 반경
};

// 모든 음식점 목록 가져오기 (인하대 후문 중심)
router.get('/restaurants', async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 50, // 기본 50개로 증가
      sort = 'rating',
      category,
      foodType,
      priceRange,
      query,
      lat = INHA_BACK_GATE.lat, // 기본값으로 인하대 후문 좌표 사용
      lng = INHA_BACK_GATE.lng,
      radius = INHA_BACK_GATE.radius
    } = req.query;
    
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const radiusInMeters = parseInt(radius);
    
    console.log('인하대 후문 중심 음식점 조회:', { latitude, longitude, radiusInMeters });
    
    // MongoDB 지리공간 쿼리
    const queryObj = {};
    
    // 인하대 후문 중심 반경 내 검색
    queryObj.location = {
      $geoWithin: {
        $centerSphere: [[longitude, latitude], radiusInMeters / 6378100]
      }
    };
    
    // 추가 필터 조건
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
    
    let restaurants = [];
    let total = 0;
    
    // 거리순 정렬인 경우 aggregation 사용
    if (sort === 'distance') {
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
            query: queryObj.location ? {} : queryObj // location 조건 제외한 나머지
          }
        }
      ];
      
      // 추가 필터 조건이 있으면 $match 단계 추가
      if (category || foodType || priceRange || query) {
        const matchObj = {};
        if (category) matchObj.categoryName = { $regex: category, $options: 'i' };
        if (foodType) matchObj.foodTypes = { $in: [foodType] };
        if (priceRange) matchObj.priceRange = priceRange;
        if (query) {
          matchObj.$or = [
            { name: { $regex: query, $options: 'i' } },
            { address: { $regex: query, $options: 'i' } },
            { categoryName: { $regex: query, $options: 'i' } }
          ];
        }
        pipeline.push({ $match: matchObj });
      }
      
      // 페이지네이션
      pipeline.push(
        { $skip: (parseInt(page) - 1) * parseInt(limit) },
        { $limit: parseInt(limit) }
      );
      
      restaurants = await Restaurant.aggregate(pipeline);
      total = await Restaurant.countDocuments(queryObj);
      
    } else {
      // 다른 정렬 방식
      let sortOption = {};
      if (sort === 'rating') {
        sortOption = { rating: -1 };
      } else if (sort === 'likes') {
        sortOption = { likes: -1 };
      } else if (sort === 'reviews') {
        sortOption = { 'reviews.length': -1 };
      } else {
        sortOption = { name: 1 };
      }
      
      restaurants = await Restaurant.find(queryObj)
        .sort(sortOption)
        .skip((parseInt(page) - 1) * parseInt(limit))
        .limit(parseInt(limit))
        .lean(); // 성능 향상을 위해 lean() 사용
      
      total = await Restaurant.countDocuments(queryObj);
    }
    
    console.log(`인하대 후문 중심 ${radiusInMeters}m 반경에서 ${restaurants.length}개 음식점 발견`);
    
    // 음식점별 카테고리 정보 로그
    const categoryCount = {};
    restaurants.forEach(r => {
      const category = r.categoryGroupCode || '기타';
      categoryCount[category] = (categoryCount[category] || 0) + 1;
    });
    console.log('카테고리별 분포:', categoryCount);
    
    res.status(200).json({
      restaurants,
      totalPages: Math.ceil(total / parseInt(limit)),
      currentPage: parseInt(page),
      total,
      source: 'database',
      location: { lat: latitude, lng: longitude, radius: radiusInMeters },
      center: '인하대 후문'
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

// 카테고리별 음식점 탐색 (인하대 후문 중심)
router.get('/restaurants/categories/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const { limit = 10 } = req.query;
    
    // 인하대 후문 중심 검색
    const queryObj = {
      location: {
        $geoWithin: {
          $centerSphere: [[INHA_BACK_GATE.lng, INHA_BACK_GATE.lat], INHA_BACK_GATE.radius / 6378100]
        }
      },
      categoryName: { $regex: category, $options: 'i' }
    };
    
    const restaurants = await Restaurant.find(queryObj)
      .sort({ rating: -1 })
      .limit(parseInt(limit));
    
    res.status(200).json({ restaurants });
  } catch (error) {
    console.error('카테고리별 음식점 조회 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 다음 행선지 추천 (인하대 후문 중심)
router.get('/restaurants/recommend/next', isAuthenticated, async (req, res) => {
  try {
    const { currentId, lat, lng } = req.query;
    
    let currentRestaurant;
    let currentCategory;
    let searchCenter = [INHA_BACK_GATE.lng, INHA_BACK_GATE.lat]; // 기본값: 인하대 후문
    
    if (currentId) {
      currentRestaurant = await Restaurant.findById(currentId);
      if (!currentRestaurant) {
        return res.status(404).json({ message: '현재 음식점을 찾을 수 없습니다.' });
      }
      currentCategory = currentRestaurant.categoryName.split(' > ')[0];
      searchCenter = currentRestaurant.location.coordinates;
    } else if (lat && lng) {
      searchCenter = [parseFloat(lng), parseFloat(lat)];
    }
    
    const User = require('../models/User');
    const user = await User.findById(req.session.user.id);
    
    const queryObj = {};
    
    // 현재 카테고리와 다른 종류 추천
    if (currentCategory) {
      if (currentCategory.includes('카페') || currentCategory.includes('디저트')) {
        queryObj.categoryName = { $not: { $regex: '카페|디저트', $options: 'i' } };
      } else {
        queryObj.categoryName = { $regex: '카페|디저트', $options: 'i' };
      }
    }
    
    // 인하대 후문 중심 1km 반경 내에서 검색
    queryObj.location = {
      $geoWithin: {
        $centerSphere: [searchCenter, 1000 / 6378100]
      }
    };
    
    if (currentId) {
      queryObj._id = { $ne: currentId };
    }
    
    let recommendations = [];
    
    // 사용자 선호도 기반 추천
    if (user && user.preferences && user.preferences.foodTypes && user.preferences.foodTypes.length > 0) {
      const preferredQuery = { ...queryObj };
      preferredQuery.foodTypes = { $in: user.preferences.foodTypes };
      
      recommendations = await Restaurant.find(preferredQuery)
        .sort({ rating: -1 })
        .limit(3);
    }
    
    // 부족하면 일반 추천으로 보완
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

// 인하대 후문 음식점 통계 API (추가)
router.get('/restaurants/stats/inha', async (req, res) => {
  try {
    const queryObj = {
      location: {
        $geoWithin: {
          $centerSphere: [[INHA_BACK_GATE.lng, INHA_BACK_GATE.lat], INHA_BACK_GATE.radius / 6378100]
        }
      }
    };
    
    const totalCount = await Restaurant.countDocuments(queryObj);
    
    // 카테고리별 통계
    const categoryStats = await Restaurant.aggregate([
      { $match: queryObj },
      { $group: { _id: '$categoryGroupCode', count: { $sum: 1 } } }
    ]);
    
    // 음식 타입별 통계
    const foodTypeStats = await Restaurant.aggregate([
      { $match: queryObj },
      { $unwind: '$foodTypes' },
      { $group: { _id: '$foodTypes', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // 평점 분포
    const ratingStats = await Restaurant.aggregate([
      { $match: queryObj },
      { 
        $group: { 
          _id: null, 
          avgRating: { $avg: '$rating' },
          maxRating: { $max: '$rating' },
          minRating: { $min: '$rating' }
        } 
      }
    ]);
    
    res.status(200).json({
      center: '인하대 후문',
      radius: INHA_BACK_GATE.radius,
      totalRestaurants: totalCount,
      categoryDistribution: categoryStats,
      foodTypeDistribution: foodTypeStats.slice(0, 10), // 상위 10개만
      ratingStatistics: ratingStats[0] || { avgRating: 0, maxRating: 0, minRating: 0 }
    });
    
  } catch (error) {
    console.error('통계 조회 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router;