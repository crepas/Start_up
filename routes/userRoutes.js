const express = require('express');
const User = require('../models/User');
const { isAuthenticated } = require('../middlewares/auth');
const router = express.Router();

// 프로필 정보 조회 라우트 (인증 필요)
router.get('/profile', isAuthenticated, async function(요청, 응답) {
  try {
    const user = await User.findById(요청.session.user.id).select('-password');
    if (!user) {
      return 응답.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }
    응답.status(200).json({ user });
  } catch (error) {
    console.error('프로필 조회 오류:', error);
    응답.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 프로필 정보 업데이트 라우트 (인증 필요) - 추가된 부분
router.post('/profile', isAuthenticated, async function(요청, 응답) {
  try {
    // 업데이트할 필드 설정
    const updateData = {};

    // 사용자 이름이 제공된 경우
    if (요청.body.username) {
      // 이미 사용 중인 사용자 이름인지 확인 (자신의 것은 제외)
      const existingUser = await User.findOne({
        username: 요청.body.username,
        _id: { $ne: 요청.session.user.id }
      });

      if (existingUser) {
        return 응답.status(400).json({ message: '이미 사용 중인 사용자 이름입니다.' });
      }

      updateData.username = 요청.body.username;
    }

    // 선호 설정이 제공된 경우
    if (요청.body.preferences) {
      updateData.preferences = {};

      // 선호하는 음식 종류가 제공된 경우
      if (요청.body.preferences.foodTypes) {
        updateData.preferences.foodTypes = 요청.body.preferences.foodTypes;
      }

      // 선호하는 가격대가 제공된 경우
      if (요청.body.preferences.priceRange) {
        updateData.preferences.priceRange = 요청.body.preferences.priceRange;
      }
    }

    // 업데이트 진행
    const updatedUser = await User.findByIdAndUpdate(
      요청.session.user.id,
      { $set: updateData },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return 응답.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    // 세션 정보도 업데이트
    if (updateData.username) {
      요청.session.user.username = updateData.username;
    }

    if (updateData.preferences) {
      요청.session.user.preferences = {
        ...요청.session.user.preferences,
        ...updateData.preferences
      };
    }

    응답.status(200).json({ message: '프로필이 성공적으로 업데이트되었습니다.', user: updatedUser });
  } catch (error) {
    console.error('프로필 업데이트 오류:', error);
    응답.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router;