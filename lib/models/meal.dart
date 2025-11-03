class Meal {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String imageUrl;
  final String? youtubeUrl;
  final Map<String, String> ingredients;
  final String? tags;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    required this.imageUrl,
    this.youtubeUrl,
    required this.ingredients,
    this.tags,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Extraer ingredientes y medidas
    Map<String, String> ingredients = {};
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients[ingredient] = measure?.toString().trim() ?? '';
      }
    }

    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Sin nombre',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      imageUrl: json['strMealThumb'] ?? '',
      youtubeUrl: json['strYoutube'],
      ingredients: ingredients,
      tags: json['strTags'],
    );
  }

  // Para la vista simplificada (búsqueda/filtros)
  factory Meal.fromJsonSimple(Map<String, dynamic> json) {
    return Meal(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Sin nombre',
      imageUrl: json['strMealThumb'] ?? '',
      ingredients: {},
    );
  }

  List<String> getInstructionSteps() {
    if (instructions == null || instructions!.isEmpty) return [];
    
    // Dividir las instrucciones en pasos (por saltos de línea o puntos)
    return instructions!
        .split(RegExp(r'\r?\n|\.\s+'))
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();
  }

  String getFormattedTags() {
    if (tags == null || tags!.isEmpty) return '';
    return tags!.split(',').map((tag) => tag.trim()).join(', ');
  }
}
