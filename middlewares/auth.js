function isAuthenticated(요청, 응답, next) {
  if (요청.session && 요청.session.user) {
    return next();
  }
  응답.status(401).json({ message: '로그인이 필요합니다.' });
}

module.exports = {
  isAuthenticated
};