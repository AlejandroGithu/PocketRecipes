import 'package:flutter/material.dart';
import '../services/meal_api_service.dart';
import '../models/meal.dart';
import '../services/database_helper.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealApiService _apiService = MealApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Meal? meal;
  bool isLoading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMealDetails();
  }

  Future<void> _loadMealDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mealId = args?['mealId'] as String?;
    
    if (mealId == null) {
      setState(() => isLoading = false);
      return;
    }

    final loadedMeal = await _apiService.getMealById(mealId);
    final favoriteStatus = await _dbHelper.isFavorite(mealId);
    
    setState(() {
      meal = loadedMeal;
      isFavorite = favoriteStatus;
      isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (meal == null) return;

    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      await _dbHelper.addFavorite(meal!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agregado a favoritos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _dbHelper.removeFavorite(meal!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliminado de favoritos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (meal == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Receta no encontrada',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: false,
            backgroundColor: const Color(0xFF1A1A1A),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                meal!.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (meal!.area != null) ...[
                        const Icon(Icons.public, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          meal!.area!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (meal!.category != null) ...[
                        const Icon(Icons.category, color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          meal!.category!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoButton('Categoría', meal!.category ?? 'N/A'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoButton('Origen', meal!.area ?? 'N/A'),
                      ),
                      if (meal!.tags != null && meal!.tags!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoButton('Tags', meal!.getFormattedTags()),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (meal!.instructions != null && meal!.instructions!.isNotEmpty) ...[
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal!.instructions!.length > 200
                          ? '${meal!.instructions!.substring(0, 200)}...'
                          : meal!.instructions!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF404040),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Ingredientes'),
                        Tab(text: 'Preparación'),
                        Tab(text: 'Nutrición'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIngredientesTab(),
                        _buildPreparacionTab(),
                        _buildNutricionTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientesTab() {
    if (meal!.ingredients.isEmpty) {
      return const Center(
        child: Text(
          'No hay ingredientes disponibles',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: meal!.ingredients.entries
          .map((entry) => _buildIngredientItem(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildIngredientItem(String name, String quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            quantity,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparacionTab() {
    if (meal!.instructions == null || meal!.instructions!.isEmpty) {
      return const Center(
        child: Text(
          'No hay instrucciones disponibles',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final steps = meal!.getInstructionSteps();
    
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: steps
          .asMap()
          .entries
          .map((entry) => _buildPreparacionStep(entry.key + 1, entry.value))
          .toList(),
    );
  }

  Widget _buildPreparacionStep(int step, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutricionTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Información nutricional no disponible en la API',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }
}