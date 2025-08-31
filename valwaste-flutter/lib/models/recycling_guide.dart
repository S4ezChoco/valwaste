class RecyclingGuide {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> instructions;
  final List<String> tips;
  final String? imageUrl;
  final bool isRecyclable;
  final String? disposalMethod;

  RecyclingGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.instructions,
    required this.tips,
    this.imageUrl,
    required this.isRecyclable,
    this.disposalMethod,
  });

  factory RecyclingGuide.fromJson(Map<String, dynamic> json) {
    return RecyclingGuide(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      instructions: List<String>.from(json['instructions']),
      tips: List<String>.from(json['tips']),
      imageUrl: json['image_url'],
      isRecyclable: json['is_recyclable'],
      disposalMethod: json['disposal_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'instructions': instructions,
      'tips': tips,
      'image_url': imageUrl,
      'is_recyclable': isRecyclable,
      'disposal_method': disposalMethod,
    };
  }
}
