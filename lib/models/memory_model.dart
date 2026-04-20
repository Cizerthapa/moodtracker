class MemoryModel {
  final DateTime date; // Changed from String
  final String desc;
  final String herFav;
  final String hisFav;
  final String lang;
  final String lat;
  final String title;
  final bool isUnique;

  MemoryModel({
    required this.date,
    required this.desc,
    required this.herFav,
    required this.hisFav,
    required this.lang,
    required this.lat,
    required this.title,
    this.isUnique = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date
          .toIso8601String(), // Store as string for database compatibility
      'desc': desc,
      'herFav': herFav,
      'hisFav': hisFav,
      'lang': lang,
      'lat': lat,
      'title': title,
      'isUnique': isUnique,
    };
  }

  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    return MemoryModel(
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      desc: map['desc'] ?? '',
      herFav: map['herFav'] ?? '',
      hisFav: map['hisFav'] ?? '',
      lang: map['lang'] ?? '',
      lat: map['lat'] ?? '',
      title: map['title'] ?? '',
      isUnique: map['isUnique'] == true,
    );
  }
}
