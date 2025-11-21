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
  // Extract ingredients and measures
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
  name: json['strMeal'] ?? 'No name',
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      imageUrl: json['strMealThumb'] ?? '',
      youtubeUrl: json['strYoutube'],
      ingredients: ingredients,
      tags: json['strTags'],
    );
  }

  // For the simplified view (search/filters)
  factory Meal.fromJsonSimple(Map<String, dynamic> json) {
    return Meal(
      id: json['idMeal'] ?? '',
  name: json['strMeal'] ?? 'No name',
      imageUrl: json['strMealThumb'] ?? '',
      ingredients: {},
    );
  }

  List<String> getInstructionSteps() {
    if (instructions == null || instructions!.isEmpty) return [];
    
  // Split the instructions into steps (by line breaks or periods)
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
