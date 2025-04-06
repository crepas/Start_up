// 새 파일 kakaoAuthRoutes.js 생성
const express = require('express');
const axios = require('axios');
const User = require('../models/User');
const router = express.Router();

router.post('/auth/kakao', async function(req, res) {
  const { accessToken } = req.body;
  
  try {
    // 카카오 API에서 사용자 정보 가져오기
    const kakaoUserResponse = await axios.get('https://kapi.kakao.com/v2/user/me', {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    
    const kakaoId = kakaoUserResponse.data.id.toString();
    const email = kakaoUserResponse.data.kakao_account?.email || `kakao_${kakaoId}@naru.app`;
    const nickname = kakaoUserResponse.data.kakao_account?.profile?.nickname || `사용자_${kakaoId.substring(0, 6)}`;
    
    // 데이터베이스에서 사용자 검색 또는 생성
    let user = await User.findOne({ email });
    
    if (!user) {
      const hashedPassword = await require('bcrypt').hash(kakaoId, 10);
      user = new User({
        username: nickname,
        email,
        password: hashedPassword
      });
      await user.save();
    }
    
    // 세션에 사용자 정보 저장
    req.session.user = {
      id: user._id,
      username: user.username,
      email: user.email
    };
    
    res.status(200).json({ message: '카카오 로그인 성공!' });
  } catch (error) {
    res.status(500).json({ message: '카카오 로그인 오류' });
  }
});

module.exports = router;