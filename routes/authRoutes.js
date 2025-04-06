const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const router = express.Router();
const path = require('path');

// // 회원가입 페이지 라우트
// router.get('/signup', function(요청, 응답) {
//   응답.sendFile(path.join(__dirname, '../signup.html'));
// });

// 회원가입 처리 라우트
router.post('/signup', async function(요청, 응답) {
  try {
    // 이미 존재하는 유저네임이나 이메일 체크
    const existingUser = await User.findOne({ 
      $or: [
        { username: 요청.body.username },
        { email: 요청.body.email }
      ]
    });
    
    if (existingUser) {
      return 응답.status(400).json({ 
        message: '이미 사용 중인 사용자 이름 또는 이메일입니다.' 
      });
    }
    
    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(요청.body.password, 10);
    
    // 새 사용자 생성
    const newUser = new User({
      username: 요청.body.username,
      email: 요청.body.email,
      password: hashedPassword,
      preferences: {
        foodTypes: 요청.body.foodTypes || [],
        priceRange: 요청.body.priceRange || '중간'
      }
    });
    
    // 사용자 저장
    await newUser.save();
    
    응답.status(201).json({ message: '회원가입 성공!' });
  } catch (error) {
    console.error('회원가입 오류:', error);
    응답.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// // 로그인 페이지 라우트
// router.get('/login', function(요청, 응답) {
//   응답.sendFile(path.join(__dirname, '../login.html'));
// });

// 로그인 처리 라우트
router.post('/login', async function(요청, 응답) {
  try {
    // 사용자 찾기
    const user = await User.findOne({ 
      $or: [
        { username: 요청.body.usernameOrEmail },
        { email: 요청.body.usernameOrEmail }
      ]
    });
    
    if (!user) {
      return 응답.status(401).json({ message: '사용자를 찾을 수 없습니다.' });
    }
    
    // 비밀번호 확인
    const validPassword = await bcrypt.compare(요청.body.password, user.password);
    if (!validPassword) {
      return 응답.status(401).json({ message: '비밀번호가 일치하지 않습니다.' });
    }
    
    // 세션에 사용자 정보 저장
    요청.session.user = { 
      id: user._id,
      username: user.username, 
      email: user.email,
      preferences: user.preferences
    };
    
    응답.status(200).json({ message: '로그인 성공!', user: { username: user.username, email: user.email } });
  } catch (error) {
    console.error('로그인 오류:', error);
    응답.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// 로그아웃 라우트
router.get('/logout', function(요청, 응답) {
  요청.session.destroy(function(err) {
    if (err) {
      return 응답.status(500).json({ message: '로그아웃 중 오류가 발생했습니다.' });
    }
    응답.clearCookie('connect.sid'); // 세션 쿠키 삭제
    응답.status(200).json({ message: '로그아웃 성공!' });
  });
});

module.exports = router;