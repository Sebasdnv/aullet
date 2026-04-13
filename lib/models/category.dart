class Category {
  final String id;
  final String name;
  final String icon;
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String,
    color: m['color'] as String,
  );
}
