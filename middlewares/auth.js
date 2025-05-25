function isAuthenticated(요청, 응답, next) {
  // 세션 기반 인증 확인
  if (요청.session && 요청.session.user) {
    return next();
  }

  // 토큰 기반 인증 확인
  const authHeader = 요청.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);

    // 여기서 토큰을 검증하는 로직을 추가해야 합니다.
    // 간단한 예시로, 토큰을 사용자 ID로 사용하여 사용자를 찾습니다.
    const User = require('../models/User');

    // 로그 추가
    console.log('토큰 기반 인증 시도:', token);

    // 토큰으로 사용자 찾기 (이 부분은 실제 토큰 저장 방식에 따라 수정 필요)
    User.findOne({ token: token })
      .then(user => {
        if (user) {
          // 사용자를 찾았으면 세션에 저장
          요청.session.user = {
            id: user._id,
            username: user.username,
            email: user.email,
            preferences: user.preferences || {}
          };
          console.log('토큰 인증 성공:', user.username);
          return next();
        }

        console.log('토큰 인증 실패: 사용자를 찾을 수 없음');
        return 응답.status(401).json({ message: '인증에 실패했습니다.' });
      })
      .catch(err => {
        console.error('토큰 인증 오류:', err);
        return 응답.status(500).json({ message: '서버 오류가 발생했습니다.' });
      });
  } else {
    // 인증 정보가 없을 경우
    return 응답.status(401).json({ message: '로그인이 필요합니다.' });
  }
}

module.exports = {
  isAuthenticated
};