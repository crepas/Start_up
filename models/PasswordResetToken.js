const mongoose = require('mongoose');

// 비밀번호 재설정 토큰 스키마
const passwordResetTokenSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: true 
  },
  token: { 
    type: String, 
    required: true 
  },
  createdAt: { 
    type: Date, 
    default: Date.now,
    expires: 3600 // 1시간 후 자동 삭제
  }
});

const PasswordResetToken = mongoose.model('PasswordResetToken', passwordResetTokenSchema);

module.exports = PasswordResetToken;