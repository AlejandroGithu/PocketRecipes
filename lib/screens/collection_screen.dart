import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';
import '../services/database_helper.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Meal> favorites = [];
  List<Map<String, dynamic>> userRecipes = [];
  bool isLoading = true;
  String userName = 'User';
  String userEmail = 'user@example.com';
  int? _userId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData();
    await _loadData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userId = prefs.getInt('userId');
      userName = prefs.getString('userName') ?? 'User';
      userEmail = prefs.getString('userEmail') ?? 'user@example.com';
    });
  }

  Future<void> _loadData() async {
    if (_userId == null) {
      if (!mounted) return;
      setState(() {
        favorites = [];
        userRecipes = [];
        isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    final favs = await _dbHelper.getFavorites(_userId!);
    final recipes = await _dbHelper.getUserRecipes(_userId!);

    if (!mounted) return;
    setState(() {
      favorites = favs;
      userRecipes = recipes;
      isLoading = false;
    });
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
                const Text(
                  'My Collection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your recipes and favorites',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF404040),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 32, color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'Sign out',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? const Color(0xFF404040) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'My Recipes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedTabIndex == 0 ? Colors.white : Colors.white38,
                                fontWeight: _selectedTabIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? const Color(0xFF404040) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Favorites',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedTabIndex == 1 ? Colors.white : Colors.white38,
                                fontWeight: _selectedTabIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildCounter(userRecipes.length.toString(), 'Recipes')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCounter(favorites.length.toString(), 'Favorites')),
                  ],
                ),
                const SizedBox(height: 20),
                _buildContent(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Log in to add recipes')),
            );
            return;
          }
          Navigator.of(context).pushNamed('/new-recipe').then((_) => _loadData());
        },
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add new recipe',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContent() {
    if (_selectedTabIndex == 0) {
      return _buildUserRecipesList();
    } else {
      return _buildFavoritesList();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Sign out?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUserRecipesList() {
    if (_userId == null) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('Log in to see your recipes', style: TextStyle(color: Colors.white38, fontSize: 16))),
      );
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (userRecipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('You haven\'t published any recipes yet', style: TextStyle(color: Colors.white38, fontSize: 16))),
      );
    }
    return Column(children: userRecipes.map((recipe) => _buildUserRecipeCard(recipe)).toList());
  }

  Widget _buildFavoritesList() {
    if (_userId == null) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('Log in to see your favorites', style: TextStyle(color: Colors.white38, fontSize: 16))),
      );
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (favorites.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('You don\'t have favorite recipes yet', style: TextStyle(color: Colors.white38, fontSize: 16))),
      );
    }
    return Column(children: favorites.map((meal) => _buildFavoriteCard(meal)).toList());
  }

  Widget _buildUserRecipeCard(Map<String, dynamic> recipe) {
    final decorationImage = _buildUserRecipeImage(recipe['imageUrl'] as String?);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/user-recipe-detail', arguments: {'recipeId': recipe['id']}).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF2A2A2A),
                image: decorationImage,
              ),
              child: decorationImage == null ? const Center(child: Icon(Icons.restaurant, size: 48, color: Colors.white38)) : null,
            ),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
              ),
            ),
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: const Text('Your recipe', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
            Positioned(
              top: 12, right: 12,
              child: GestureDetector(
                onTap: () => _showDeleteDialog(recipe),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.delete, color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe['name'] ?? 'No name', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recipe['description'] ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (recipe['time'] != null) ...[
                        const Icon(Icons.access_time, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(recipe['time'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(width: 12),
                      ],
                      if (recipe['difficulty'] != null) ...[
                        const Icon(Icons.signal_cellular_alt, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(recipe['difficulty'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
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

  Widget _buildFavoriteCard(Meal meal) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/recipe', arguments: {'mealId': meal.id}).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(image: NetworkImage(meal.imageUrl), fit: BoxFit.cover),
              ),
            ),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
              ),
            ),
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.favorite, color: Colors.red, size: 20),
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

  void _showDeleteDialog(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Delete recipe?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (_userId == null) {
                Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Log in to delete recipes')));
                return;
              }
              final recipeId = recipe['id'] as String;
              final imagePath = recipe['imageUrl'] as String?;
              await _dbHelper.deleteUserRecipe(recipeId, _userId!);
              Navigator.pop(context);
              if (imagePath != null && imagePath.isNotEmpty) {
                final imageFile = File(imagePath);
                if (await imageFile.exists()) {
                  try { await imageFile.delete(); } catch (_) {}
                }
              }
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildUserRecipeImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) {
      return DecorationImage(image: NetworkImage(imagePath), fit: BoxFit.cover);
    }
    final file = File(imagePath);
    if (!file.existsSync()) return null;
    return DecorationImage(image: FileImage(file), fit: BoxFit.cover);
  }
}