import 'dart:ui';

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'description': description,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: Color(map['color']),
      description: map['description'],
    );
  }
}