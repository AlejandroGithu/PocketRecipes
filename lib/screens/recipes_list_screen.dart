import 'package:flutter/material.dart';
import '../services/meal_api_service.dart';
import '../models/meal.dart';
import '../services/database_helper.dart';
import 'ingredients_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final MealApiService _apiService = MealApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String? selectedCategory;
  String? selectedIngredient;
  List<Meal> meals = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  Map<String, bool> favoritesStatus = {};
  int? _userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _userId = prefs.getInt('userId'));
    await _loadRandomMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritesStatus() async {
    if (_userId == null) {
      if (!mounted) return;
      setState(() => favoritesStatus = {for (var meal in meals) meal.id: false});
      return;
    }
    Map<String, bool> status = {};
    for (var meal in meals) {
      status[meal.id] = await _dbHelper.isFavorite(meal.id, _userId!);
    }
    if (!mounted) return;
    setState(() => favoritesStatus = status);
  }

  Future<void> _loadRandomMeals() async {
    setState(() { isLoading = true; selectedCategory = null; selectedIngredient = null; isSearching = false; });
    final randomMeals = await _apiService.getRandomMeals(6);
    if (!mounted) return;
    setState(() { meals = randomMeals; isLoading = false; });
    _loadFavoritesStatus();
  }

  Future<void> _filterByCategory(String category) async {
    setState(() { selectedCategory = category; selectedIngredient = null; isSearching = false; isLoading = true; });
    List<Meal> filtered;
    if (category == 'All') {
      filtered = await _apiService.getRandomMeals(6);
    } else {
      final simpleMeals = await _apiService.filterByCategory(category);
      filtered = [];
      for (var simpleMeal in simpleMeals.take(6)) {
        final fullMeal = await _apiService.getMealById(simpleMeal.id);
        if (fullMeal != null) filtered.add(fullMeal);
      }
    }
    if (!mounted) return;
    setState(() { meals = filtered; isLoading = false; });
    _loadFavoritesStatus();
  }

  Future<void> _filterByIngredient(String ingredient) async {
    setState(() { selectedIngredient = ingredient; selectedCategory = null; isSearching = false; isLoading = true; });
    final simpleMeals = await _apiService.filterByIngredient(ingredient);
    List<Meal> filtered = [];
    for (var simpleMeal in simpleMeals.take(6)) {
      final fullMeal = await _apiService.getMealById(simpleMeal.id);
      if (fullMeal != null) filtered.add(fullMeal);
    }
    if (!mounted) return;
    setState(() { meals = filtered; isLoading = false; });
    _loadFavoritesStatus();
  }

  Future<void> _searchMeals(String query) async {
    if (query.trim().isEmpty) { _loadRandomMeals(); return; }
    setState(() { isSearching = true; selectedCategory = null; selectedIngredient = null; isLoading = true; });
    final results = await _apiService.searchMealByName(query);
    if (!mounted) return;
    setState(() { meals = results; isLoading = false; });
    _loadFavoritesStatus();
  }

  Future<void> _navigateToIngredients() async {
    final selectedIngredients = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (context) => const IngredientsScreen()),
    );
    if (selectedIngredients != null && selectedIngredients.isNotEmpty) {
      setState(() { isSearching = false; selectedCategory = null; selectedIngredient = null; isLoading = true; });
      List<Meal> allResults = [];
      for (var ingredient in selectedIngredients) {
        final simpleMeals = await _apiService.filterByIngredient(ingredient);
        for (var simpleMeal in simpleMeals.take(10)) {
          final fullMeal = await _apiService.getMealById(simpleMeal.id);
          if (fullMeal != null && !allResults.any((m) => m.id == fullMeal.id)) {
            allResults.add(fullMeal);
          }
        }
      }
      setState(() { meals = allResults; isLoading = false; });
      _loadFavoritesStatus();
    }
  }

  Future<void> _toggleFavorite(Meal meal) async {
    if (_userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log in to manage favorites'), duration: Duration(seconds: 1)));
      return;
    }
    final isFav = favoritesStatus[meal.id] ?? false;
    if (isFav) {
      await _dbHelper.removeFavorite(meal.id, _userId!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites'), duration: Duration(seconds: 1)));
    } else {
      await _dbHelper.addFavorite(meal, _userId!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to favorites'), duration: Duration(seconds: 1)));
    }
    if (!mounted) return;
    setState(() => favoritesStatus[meal.id] = !isFav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, Chef!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('What will you cook today?', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _searchMeals,
                  decoration: InputDecoration(
                    hintText: 'Search recipes, ingredients ...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, color: Colors.white38), onPressed: () { _searchController.clear(); _loadRandomMeals(); })
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                if (!isSearching) ...[
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip('All'), const SizedBox(width: 8),
                        _buildCategoryChip('Seafood'), const SizedBox(width: 8),
                        _buildCategoryChip('Dessert'), const SizedBox(width: 8),
                        _buildCategoryChip('Vegetarian'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Ingredients', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: _navigateToIngredients,
                        child: const Text('See All', style: TextStyle(color: Colors.white38, fontSize: 14, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildIngredientCard('chicken', '🍗'), const SizedBox(width: 12),
                        _buildIngredientCard('beef', '🥩'), const SizedBox(width: 12),
                        _buildIngredientCard('salmon', '🐟'), const SizedBox(width: 12),
                        _buildIngredientCard('pork', '🥓'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  isSearching ? 'Search results' : selectedCategory != null ? 'Recipes for $selectedCategory' : selectedIngredient != null ? 'Recipes with $selectedIngredient' : 'Recommended Recipes',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white)))
                else if (meals.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No recipes found', style: TextStyle(color: Colors.white38, fontSize: 16))))
                else
                  ...meals.map((meal) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildRecipeCard(meal))),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => _filterByCategory(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildIngredientCard(String ingredient, String emoji) {
    final isSelected = selectedIngredient == ingredient;
    return GestureDetector(
      onTap: () => _filterByIngredient(ingredient),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(ingredient, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Meal meal) {
    final isFav = favoritesStatus[meal.id] ?? false;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/recipe', arguments: {'mealId': meal.id}).then((_) => _loadFavoritesStatus()),
      child: Container(
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: NetworkImage(meal.imageUrl), fit: BoxFit.cover)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
                ),
              ),
            ),
            Positioned(
              top: 12, right: 12,
              child: GestureDetector(
                onTap: () => _toggleFavorite(meal),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(meal.category ?? 'No category', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.public, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(meal.area ?? 'International', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(Icons.category, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(meal.category ?? 'Various', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}