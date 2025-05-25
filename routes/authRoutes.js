const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const router = express.Router();
const path = require('path');

const crypto = require('crypto');
const nodemailer = require('nodemailer');

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

    // 토큰 생성
    const crypto = require('crypto');
    const token = crypto.randomBytes(48).toString('hex');

    // 사용자 문서에 토큰 저장
    user.token = token;
    await user.save();

    // 디버깅용 로그
    console.log('로그인 성공:', user.username);
    console.log('생성된 토큰:', token);

    // 세션에 사용자 정보 저장
    요청.session.user = {
      id: user._id,
      username: user.username,
      email: user.email,
      preferences: user.preferences
    };

    console.log('세션 정보:', 요청.session.user);

    // 토큰을 포함한 응답 반환
    응답.status(200).json({
      message: '로그인 성공!',
      token: token,
      user: {
        username: user.username,
        email: user.email
      }
    });
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

// 비밀번호 찾기 라우트 추가
router.post('/auth/forgot-password', async function(req, res) {
  try {
    const { email } = req.body;

    // 이메일로 사용자 찾기
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(404).json({ message: '해당 이메일로 등록된 사용자가 없습니다.' });
    }

    // 임시 비밀번호 생성 (8자리 랜덤 문자열)
    const tempPassword = crypto.randomBytes(4).toString('hex');

    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    // 사용자 비밀번호 업데이트
    user.password = hashedPassword;
    await user.save();

    // 이메일 전송 설정
    const transporter = nodemailer.createTransport({
      service: 'Gmail', // 또는 다른 이메일 서비스
      auth: {
        user: 'your-email@gmail.com', // 실제 이메일 주소로 변경
        pass: 'your-password' // 앱 비밀번호 또는 실제 비밀번호로 변경
      }
    });

    // 이메일 내용
    const mailOptions = {
      from: 'kimsw021104@gmail.com',
      to: email,
      subject: '나루나루 - 임시 비밀번호 안내',
      html: `
        <h1>나루나루 임시 비밀번호 안내</h1>
        <p>안녕하세요, 나루나루 서비스입니다.</p>
        <p>요청하신 임시 비밀번호는 다음과 같습니다:</p>
        <h2 style="color: #A0CC71;">${tempPassword}</h2>
        <p>로그인 후 보안을 위해 비밀번호를 변경해주세요.</p>
        <p>이 요청을 하지 않으셨다면, 이 이메일을 무시하셔도 됩니다.</p>
      `
    };

    // 이메일 전송
    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: '임시 비밀번호가 이메일로 전송되었습니다. 메일함을 확인해주세요.' });
  } catch (error) {
    console.error('비밀번호 찾기 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router;

