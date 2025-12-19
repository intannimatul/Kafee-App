class Drink {
  final int id;
  final String name;
  final String description;
  final int price;
  final String imagePath;
  final String category;

  Drink({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.category,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: json['price'],
      imagePath: json['image_path'],
      category: json['category'],
    );
  }
}
