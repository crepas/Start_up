const express = require('express');
const path = require('path');
const { isAuthenticated } = require('../middlewares/auth');
const router = express.Router();

// // 홈 페이지 라우트
// router.get('/home', isAuthenticated, function(요청, 응답) {
//   응답.sendFile(path.join(__dirname, '../home.html'));
// });

// 메인 페이지 접속 시 홈으로 리다이렉트
router.get('/', function(요청, 응답) {
  if (요청.session && 요청.session.user) {
    응답.redirect('/home');
  } else {
    응답.redirect('/login');
  }
});

// // 지도 페이지 라우트
// router.get('/map', isAuthenticated, function(요청, 응답) {
//   응답.sendFile(path.join(__dirname, '../map.html'));
// });

module.exports = router;