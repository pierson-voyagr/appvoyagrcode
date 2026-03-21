class Location {
  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final String? category;
  final String? description;
  final String? image;
  final String? address;

  Location({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.category,
    this.description,
    this.image,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'description': description,
      'image': image,
      'address': address,
    };
  }

  Location copyWith({
    String? id,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    String? category,
    String? description,
    String? image,
    String? address,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      description: description ?? this.description,
      image: image ?? this.image,
      address: address ?? this.address,
    );
  }
}
