const axios = require('axios');

// REST API 키를 실제 키로 변경하세요
const KAKAO_API_KEY = '4e4572f409f9b0cd5dc1f574779a03a7';

async function testKakaoLocalAPI() {
  try {
    const response = await axios.get('https://dapi.kakao.com/v2/local/search/keyword.json', {
      headers: {
        Authorization: `KakaoAK ${KAKAO_API_KEY}` // 주의: 앞에 'KakaoAK'와 API 키 사이에 공백이 있어야 합니다
      },
      params: {
        query: '맛집',
        x: '126.6503',
        y: '37.4512',
        radius: 2000
      }
    });
    
    console.log('API 응답:', response.data);
  } catch (error) {
    console.error('API 오류:', error.response ? error.response.data : error.message);
  }
}

testKakaoLocalAPI();