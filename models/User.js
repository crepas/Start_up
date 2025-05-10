const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  token: { type: String },
  preferences: {
    foodTypes: [String],
    priceRange: { type: String, default: '중간' }
  },
  // 추가된 부분: 사용자가 좋아요한 음식점 ID 목록
  likedRestaurants: [{ 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Restaurant' 
  }],
  registeredDate: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

module.exports = User;