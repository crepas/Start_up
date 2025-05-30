// scripts/update-images-only.js 새로 생성
const { updateExistingRestaurantImages } = require('./import-inha-restaurants');

updateExistingRestaurantImages().then(() => {
  console.log('이미지 업데이트 완료!');
  process.exit(0);
}).catch(error => {
  console.error('이미지 업데이트 오류:', error);
  process.exit(1);
});