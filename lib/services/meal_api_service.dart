import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../models/category.dart';

class MealApiService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Buscar comida por nombre
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
      print('Error buscando comida: $e');
      return [];
    }
  }

  // Buscar comida por primera letra
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
      print('Error buscando por letra: $e');
      return [];
    }
  }

  // Obtener detalles de comida por ID
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
      print('Error obteniendo detalles: $e');
      return null;
    }
  }

  // Obtener comida aleatoria
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
      print('Error obteniendo comida aleatoria: $e');
      return null;
    }
  }

  // Obtener múltiples comidas aleatorias
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

  // Listar todas las categorías
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
      print('Error obteniendo categorías: $e');
      return [];
    }
  }

  // Listar ingredientes
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
      print('Error obteniendo ingredientes: $e');
      return [];
    }
  }

  // Filtrar por ingrediente principal
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
      print('Error filtrando por ingrediente: $e');
      return [];
    }
  }

  // Filtrar por categoría
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
      print('Error filtrando por categoría: $e');
      return [];
    }
  }

  // Filtrar por área/país
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
      print('Error filtrando por área: $e');
      return [];
    }
  }

  // Listar todas las áreas
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
      print('Error obteniendo áreas: $e');
      return [];
    }
  }
}
