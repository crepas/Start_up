const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const User = require('../models/User');
const PasswordResetToken = require('../models/PasswordResetToken');
const { sendEmail } = require('../config/email');
const router = express.Router();

// 비밀번호 재설정 요청 (이메일 발송)
router.post('/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    // 이메일 유효성 검사
    if (!email) {
      return res.status(400).json({ message: '이메일을 입력해주세요.' });
    }

    // 사용자 이메일 검색
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: '해당 이메일로 등록된 사용자가 없습니다.' });
    }

    // 기존 토큰 삭제
    await PasswordResetToken.deleteMany({ userId: user._id });

    // 새 토큰 생성
    const resetToken = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    // 토큰 저장
    await new PasswordResetToken({
      userId: user._id,
      token: hashedToken
    }).save();

    // 재설정 URL 생성 (프론트엔드 URL로 변경 필요)
    const resetUrl = `${req.protocol}://${req.get('host')}/auth/reset-password/${resetToken}`;
    
    // 이메일 내용 작성
    const emailHtml = `
  <h2>안녕하세요, ${user.username}님!</h2>
  <p>비밀번호 재설정을 요청하셨습니다.</p>
  <p>아래 링크를 클릭하여 비밀번호를 재설정해주세요</p>
  <p style="margin: 20px 0;">
    <a href="${resetUrl}" style="display: inline-block; padding: 10px 15px; background-color: #A0CC71; color: white; text-decoration: none; border-radius: 5px;">
      비밀번호 재설정하기
    </a>
  </p>
  <p>만약 비밀번호 재설정을 요청하지 않으셨다면, 이 이메일을 무시해주세요.</p>
  <p>감사합니다,<br>나루나루 팀</p>
`;

    // 이메일 전송
    const emailSent = await sendEmail(
      user.email,
      '나루나루 - 비밀번호 재설정',
      emailHtml
    );

    if (emailSent) {
      res.status(200).json({ message: '비밀번호 재설정 링크가 이메일로 전송되었습니다.' });
    } else {
      res.status(500).json({ message: '이메일 전송에 실패했습니다. 다시 시도해주세요.' });
    }
  } catch (error) {
    console.error('비밀번호 재설정 요청 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다. 다시 시도해주세요.' });
  }
});

// 비밀번호 재설정 페이지 렌더링
router.get('/auth/reset-password/:token', async (req, res) => {
  try {
    const { token } = req.params;
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

    // 토큰 유효성 검사
    const resetToken = await PasswordResetToken.findOne({ token: hashedToken });
    if (!resetToken) {
      return res.status(400).send(`
        <html>
          <head>
            <title>비밀번호 재설정 오류</title>
            <style>
              body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; }
              .error-container { max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #f44336; border-radius: 5px; }
              h2 { color: #f44336; }
            </style>
          </head>
          <body>
            <div class="error-container">
              <h2>링크가 유효하지 않습니다</h2>
              <p>비밀번호 재설정 링크가 만료되었거나 유효하지 않습니다.</p>
              <p>비밀번호 재설정을 다시 요청해주세요.</p>
              <a href="/login">로그인 페이지로 돌아가기</a>
            </div>
          </body>
        </html>
      `);
    }

    // 비밀번호 재설정 폼 렌더링
    res.send(`
      <html>
        <head>
          <title>비밀번호 재설정</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding-top: 50px; }
            .form-container { max-width: 400px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
            input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 5px; box-sizing: border-box; }
            button { width: 100%; padding: 10px; background-color: #A0CC71; color: white; border: none; border-radius: 5px; cursor: pointer; }
            .error { color: red; margin-top: 5px; }
            .success { color: green; margin-top: 5px; }
          </style>
        </head>
        <body>
          <div class="form-container">
            <h2>새 비밀번호 설정</h2>
            <form id="reset-form">
              <input type="hidden" id="token" value="${token}">
              <div>
                <input type="password" id="password" placeholder="새 비밀번호" required>
              </div>
              <div>
                <input type="password" id="confirmPassword" placeholder="비밀번호 확인" required>
              </div>
              <div id="error-message" class="error" style="display: none;"></div>
              <div id="success-message" class="success" style="display: none;"></div>
              <button type="submit">비밀번호 변경</button>
            </form>
          </div>
          
          <script>
            document.getElementById('reset-form').addEventListener('submit', async (e) => {
              e.preventDefault();
              
              const password = document.getElementById('password').value;
              const confirmPassword = document.getElementById('confirmPassword').value;
              const token = document.getElementById('token').value;
              const errorDisplay = document.getElementById('error-message');
              const successDisplay = document.getElementById('success-message');
              
              errorDisplay.style.display = 'none';
              successDisplay.style.display = 'none';
              
              if (password !== confirmPassword) {
                errorDisplay.textContent = '비밀번호가 일치하지 않습니다.';
                errorDisplay.style.display = 'block';
                return;
              }
              
              try {
                const response = await fetch('/auth/reset-password', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ token, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                  successDisplay.textContent = data.message;
                  successDisplay.style.display = 'block';
                  document.getElementById('reset-form').reset();
                  
                  // 3초 후 로그인 페이지로 리다이렉트
                  setTimeout(() => {
                    window.location.href = '/login';
                  }, 3000);
                } else {
                  errorDisplay.textContent = data.message;
                  errorDisplay.style.display = 'block';
                }
              } catch (error) {
                errorDisplay.textContent = '오류가 발생했습니다. 다시 시도해주세요.';
                errorDisplay.style.display = 'block';
              }
            });
          </script>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('비밀번호 재설정 페이지 오류:', error);
    res.status(500).send('서버 오류가 발생했습니다. 다시 시도해주세요.');
  }
});

// 비밀번호 재설정 처리
router.post('/auth/reset-password', async (req, res) => {
  try {
    const { token, password } = req.body;
    
    // 토큰 유효성 검사
    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const resetToken = await PasswordResetToken.findOne({ token: hashedToken });

    if (!resetToken) {
      return res.status(400).json({ message: '유효하지 않거나 만료된 토큰입니다.' });
    }

    // 사용자 찾기
    const user = await User.findById(resetToken.userId);
    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    // 비밀번호 해싱 및 업데이트
    const hashedPassword = await bcrypt.hash(password, 10);
    user.password = hashedPassword;
    await user.save();

    // 사용된 토큰 삭제
    await PasswordResetToken.deleteOne({ _id: resetToken._id });

    res.status(200).json({ message: '비밀번호가 성공적으로 변경되었습니다.' });
  } catch (error) {
    console.error('비밀번호 재설정 처리 오류:', error);
    res.status(500).json({ message: '서버 오류가 발생했습니다. 다시 시도해주세요.' });
  }
});

module.exports = router;