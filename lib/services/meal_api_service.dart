import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../models/category.dart';

class MealApiService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Search meals by name
  Future<List<Meal>> searchMealByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?s=$name'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((meal) => Meal.fromJson(meal))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error searching meals: $e');
      return [];
    }
  }

  // Search meals by first letter
  Future<List<Meal>> searchMealByLetter(String letter) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.php?f=$letter'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((meal) => Meal.fromJson(meal))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error searching by letter: $e');
      return [];
    }
  }

  // Get meal details by ID
  Future<Meal?> getMealById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lookup.php?i=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null || data['meals'].isEmpty) return null;
        
        return Meal.fromJson(data['meals'][0]);
      }
      return null;
    } catch (e) {
  print('Error fetching details: $e');
      return null;
    }
  }

  // Get a random meal
  Future<Meal?> getRandomMeal() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/random.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null || data['meals'].isEmpty) return null;
        
        return Meal.fromJson(data['meals'][0]);
      }
      return null;
    } catch (e) {
  print('Error fetching random meal: $e');
      return null;
    }
  }

  // Get multiple random meals
  Future<List<Meal>> getRandomMeals(int count) async {
    List<Meal> meals = [];
    for (int i = 0; i < count; i++) {
      final meal = await getRandomMeal();
      if (meal != null) {
        meals.add(meal);
      }
    }
    return meals;
  }

  // List all categories
  Future<List<MealCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] == null) return [];
        
        return (data['categories'] as List)
            .map((category) => MealCategory.fromJson(category))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error fetching categories: $e');
      return [];
    }
  }

  // List ingredients
  Future<List<Ingredient>> getIngredients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list.php?i=list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((ingredient) => Ingredient.fromJson(ingredient))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error fetching ingredients: $e');
      return [];
    }
  }

  // Filter by main ingredient
  Future<List<Meal>> filterByIngredient(String ingredient) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?i=$ingredient'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((meal) => Meal.fromJsonSimple(meal))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error filtering by ingredient: $e');
      return [];
    }
  }

  // Filter by category
  Future<List<Meal>> filterByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?c=$category'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((meal) => Meal.fromJsonSimple(meal))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error filtering by category: $e');
      return [];
    }
  }

  // Filter by area/country
  Future<List<Meal>> filterByArea(String area) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter.php?a=$area'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((meal) => Meal.fromJsonSimple(meal))
            .toList();
      }
      return [];
    } catch (e) {
  print('Error filtering by area: $e');
      return [];
    }
  }

  // List all areas
  Future<List<String>> getAreas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list.php?a=list'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) return [];
        
        return (data['meals'] as List)
            .map((area) => area['strArea'] as String)
            .toList();
      }
      return [];
    } catch (e) {
  print('Error fetching areas: $e');
      return [];
    }
  }
}
