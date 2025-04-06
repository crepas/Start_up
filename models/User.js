const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  preferences: {
    foodTypes: [String],  // 선호하는 음식 종류 (예: 한식, 일식, 양식 등)
    priceRange: String,   // 선호하는 가격대
  },
  registeredDate: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

module.exports = User;