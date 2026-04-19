import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String? id;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? imageUrl;
  final int imageCount;
  final String? herFavStory;
  final String? hisFavStory;
  final bool isUnique;
  final DateTime? memoryDate;
  final DateTime? timestamp;
  final DateTime? deletedAt;

  const MemoryModel({
    this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.imageCount = 0,
    this.herFavStory,
    this.hisFavStory,
    this.isUnique = false,
    this.memoryDate,
    this.timestamp,
    this.deletedAt,
  });

  factory MemoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String?,
      imageCount: data['imageCount'] as int? ?? 0,
      herFavStory: data['herFavStory'] as String?,
      hisFavStory: data['hisFavStory'] as String?,
      isUnique: data['isUnique'] as bool? ?? false,
      memoryDate: (data['memoryDate'] as Timestamp?)?.toDate(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'imageCount': imageCount,
      'herFavStory': herFavStory,
      'hisFavStory': hisFavStory,
      'isUnique': isUnique,
      'memoryDate': memoryDate != null ? Timestamp.fromDate(memoryDate!) : null,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  MemoryModel copyWith({
    String? id,
    String? title,
    String? description,
    double? lat,
    double? lng,
    String? imageUrl,
    int? imageCount,
    String? herFavStory,
    String? hisFavStory,
    bool? isUnique,
    DateTime? memoryDate,
    DateTime? timestamp,
    DateTime? deletedAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      imageCount: imageCount ?? this.imageCount,
      herFavStory: herFavStory ?? this.herFavStory,
      hisFavStory: hisFavStory ?? this.hisFavStory,
      isUnique: isUnique ?? this.isUnique,
      memoryDate: memoryDate ?? this.memoryDate,
      timestamp: timestamp ?? this.timestamp,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isDeleted => deletedAt != null;

  @override
  String toString() => 'MemoryModel(id: $id, title: $title, date: $memoryDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MemoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'imageCount': imageCount,
      'herFavStory': herFavStory,
      'hisFavStory': hisFavStory,
      'isUnique': isUnique,
      'memoryDate': memoryDate?.toIso8601String(),
      'timestamp': timestamp?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    return MemoryModel(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] as String?,
      imageCount: map['imageCount'] as int? ?? 0,
      herFavStory: map['herFavStory'] as String?,
      hisFavStory: map['hisFavStory'] as String?,
      isUnique: map['isUnique'] as bool? ?? false,
      memoryDate: map['memoryDate'] != null ? DateTime.parse(map['memoryDate']) : null,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }
}
