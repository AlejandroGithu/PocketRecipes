class MealCategory {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  MealCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: json['idCategory'] ?? '',
      name: json['strCategory'] ?? 'Sin nombre',
      imageUrl: json['strCategoryThumb'] ?? '',
      description: json['strCategoryDescription'] ?? '',
    );
  }
}

class Ingredient {
  final String id;
  final String name;
  final String? description;

  Ingredient({
    required this.id,
    required this.name,
    this.description,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['idIngredient'] ?? '',
      name: json['strIngredient'] ?? 'Sin nombre',
      description: json['strDescription'],
    );
  }

  String getImageUrl({String size = 'medium'}) {
    final formattedName = name.toLowerCase().replaceAll(' ', '-');
    return 'https://www.themealdb.com/images/ingredients/$formattedName-$size.png';
  }
}
