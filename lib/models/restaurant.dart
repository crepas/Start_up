// models/food.dart
import 'package:flutter/material.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String roadAddress;
  final double lat;
  final double lng;
  final String categoryName;
  final List<String> foodTypes;
  final String phone;
  final String placeUrl;
  final String priceRange;
  final double rating;
  final int likes;
  final List<Review> reviews;
  final List<String> images;
  final bool isLiked;
  final bool isAd;
  final bool isOpen;
  final bool hasParking;
  final bool hasDelivery;
  final bool hasReservation;
  final bool hasWifi;
  final bool isPetFriendly;
  final int reviewCount;
  final DateTime createdAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.roadAddress,
    required this.lat,
    required this.lng,
    required this.categoryName,
    required this.foodTypes,
    required this.phone,
    required this.placeUrl,
    required this.priceRange,
    required this.rating,
    required this.likes,
    required this.reviews,
    required this.images,
    this.isLiked = false,
    this.isAd = false,
    this.isOpen = true,
    this.hasParking = false,
    this.hasDelivery = false,
    this.hasReservation = false,
    this.hasWifi = false,
    this.isPetFriendly = false,
    this.reviewCount = 0,
    required this.createdAt,
  });

  // JSON에서 Restaurant 객체로 변환
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final coordinates = location['coordinates'] ?? [];
    
    // coordinates 배열이 유효한지 확인
    double lat = 0.0;
    double lng = 0.0;
    if (coordinates.length >= 2) {
      lat = (coordinates[1] ?? 0.0).toDouble();
      lng = (coordinates[0] ?? 0.0).toDouble();
    }

    return Restaurant(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      roadAddress: json['roadAddress'] ?? '',
      lat: lat,
      lng: lng,
      categoryName: json['categoryName'] ?? '',
      foodTypes: List<String>.from(json['foodTypes'] ?? []),
      phone: json['phone'] ?? '',
      placeUrl: json['placeUrl'] ?? '',
      priceRange: json['priceRange'] ?? '중간',
      rating: json['rating']?.toDouble() ?? 0.0,
      likes: json['likes'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => Review.fromJson(review))
          .toList() ?? [],
      images: List<String>.from(json['images'] ?? []),
      isLiked: json['isLiked'] ?? false,
      isAd: json['isAd'] ?? false,
      isOpen: json['isOpen'] ?? true,
      hasParking: json['hasParking'] ?? false,
      hasDelivery: json['hasDelivery'] ?? false,
      hasReservation: json['hasReservation'] ?? false,
      hasWifi: json['hasWifi'] ?? false,
      isPetFriendly: json['isPetFriendly'] ?? false,
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Restaurant 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'roadAddress': roadAddress,
      'location': {
        'coordinates': [lng, lat]
      },
      'categoryName': categoryName,
      'foodTypes': foodTypes,
      'phone': phone,
      'placeUrl': placeUrl,
      'priceRange': priceRange,
      'rating': rating,
      'likes': likes,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'images': images,
      'isLiked': isLiked,
      'isAd': isAd,
      'isOpen': isOpen,
      'hasParking': hasParking,
      'hasDelivery': hasDelivery,
      'hasReservation': hasReservation,
      'hasWifi': hasWifi,
      'isPetFriendly': isPetFriendly,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Review {
  final String? userId;
  final String username;
  final String comment;
  final double rating;
  final DateTime date;
  final List<String> images;

  Review({
    this.userId,
    required this.username,
    required this.comment,
    required this.rating,
    required this.date,
    this.images = const [],
  });

  // JSON에서 Review 객체로 변환
  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Review(
      userId: json['userId'],
      username: json['username'] ?? '',
      comment: json['comment'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      date: parseDate(json['date']),
      images: List<String>.from(json['images'] ?? []),
    );
  }

  // Review 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'comment': comment,
      'rating': rating,
      'date': date.toIso8601String(),
      'images': images,
    };
  }
}