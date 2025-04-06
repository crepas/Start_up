const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const MongoStore = require('connect-mongo');
require('dotenv').config();

// 데이터베이스 연결
const connectDB = require('./config/db');
connectDB();

// 라우트 가져오기
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const pageRoutes = require('./routes/pageRoutes');
const kakaoAuthRoutes = require('./routes/kakaoAuthRoutes');
const app = express();

// CORS 설정 추가 (앱에서 서버 접근 허용)
const cors = require('cors');
app.use(cors({
  origin: "*",
  credentials: true
}));

// 미들웨어 설정
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static('public'));

// 세션 설정
app.use(session({
  secret: 'naruApp_secret_key', // 실제 프로덕션에서는 환경변수로 관리하세요
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production', // HTTPS에서만 쿠키 전송
    maxAge: 1000 * 60 * 60 * 24 // 24시간
  },
  store: MongoStore.create({ 
    mongoUrl: 'mongodb://localhost:27017/naruApp',
    collectionName: 'sessions' 
  })
}));

// 라우트 설정
app.use('/', authRoutes);
app.use('/', userRoutes);
app.use('/', pageRoutes);
// 라우트 등록
app.use('/', kakaoAuthRoutes);

// 서버 시작
const PORT = process.env.PORT || 8081;
app.listen(PORT,'0.0.0.0', function(){
    console.log(`Server listening on port ${PORT}`);
});

