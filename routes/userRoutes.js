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

module.exports = router;