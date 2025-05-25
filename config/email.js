const nodemailer = require('nodemailer');

// 네이버 메일 전송을 위한 Nodemailer 설정
const transporter = nodemailer.createTransport({
  host: 'smtp.naver.com',
  port: 587,
  secure: false, // TLS 사용
  auth: {
    user: process.env.EMAIL_USER || 'your-naver-id@naver.com', // .env 파일에서 가져오거나 직접 설정
    pass: process.env.EMAIL_PASS || 'your-naver-password' // .env 파일에서 가져오거나 직접 설정
  }
});

// 이메일 전송 함수
const sendEmail = async (to, subject, html) => {
  try {
    const mailOptions = {
      from: process.env.EMAIL_USER || 'your-naver-id@naver.com',
      to,
      subject,
      html
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('이메일 전송 성공:', info.messageId);
    return true;
  } catch (error) {
    console.error('이메일 전송 오류:', error);
    return false;
  }
};

module.exports = { sendEmail };