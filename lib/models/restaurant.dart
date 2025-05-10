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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final coordinates = location['coordinates'];

    return Restaurant(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      roadAddress: json['roadAddress'] ?? '',
      lat: coordinates[1].toDouble(),
      lng: coordinates[0].toDouble(),
      categoryName: json['categoryName'],
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
    );
  }
}

class Review {
  final String? userId;
  final String username;
  final String comment;
  final double rating;
  final DateTime date;

  Review({
    this.userId,
    required this.username,
    required this.comment,
    required this.rating,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      userId: json['userId'],
      username: json['username'],
      comment: json['comment'],
      rating: json['rating']?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
    );
  }
}