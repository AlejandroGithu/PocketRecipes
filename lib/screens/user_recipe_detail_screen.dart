import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class UserRecipeDetailScreen extends StatefulWidget {
  const UserRecipeDetailScreen({super.key});

  @override
  State<UserRecipeDetailScreen> createState() => _UserRecipeDetailScreenState();
}

class _UserRecipeDetailScreenState extends State<UserRecipeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? recipe;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final recipeId = args?['recipeId'] as String?;
    
    if (recipeId == null) {
      setState(() => isLoading = false);
      return;
    }

    final loadedRecipe = await _dbHelper.getUserRecipeById(recipeId);
    
    setState(() {
      recipe = loadedRecipe;
      isLoading = false;
    });
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

    if (recipe == null) {
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
            flexibleSpace: FlexibleSpaceBar(
              background: recipe!['imageUrl'] != null
                  ? Image.network(
                      recipe!['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 80, color: Colors.white38),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 80, color: Colors.white38),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe!['name'] ?? 'Sin nombre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tu receta',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (recipe!['time'] != null) ...[
                        Expanded(
                          child: _buildInfoButton('Tiempo', recipe!['time']),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (recipe!['servings'] != null) ...[
                        Expanded(
                          child: _buildInfoButton('Porciones', recipe!['servings']),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (recipe!['difficulty'] != null) ...[
                        Expanded(
                          child: _buildInfoButton('Dificultad', recipe!['difficulty']),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (recipe!['description'] != null && recipe!['description'].toString().isNotEmpty) ...[
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
                      recipe!['description'],
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
    final ingredients = recipe!['ingredients'] as List<dynamic>? ?? [];

    if (ingredients.isEmpty) {
      return const Center(
        child: Text(
          'No hay ingredientes disponibles',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: ingredients
          .map((ing) => _buildIngredientItem(
                ing['ingredient'] as String,
                ing['measure'] as String? ?? '',
              ))
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
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
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
    final steps = recipe!['steps'] as List<dynamic>? ?? [];

    if (steps.isEmpty) {
      return const Center(
        child: Text(
          'No hay pasos de preparación disponibles',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: steps
          .asMap()
          .entries
          .map((entry) => _buildPreparacionStep(
                entry.value['stepNumber'] as int,
                entry.value['description'] as String,
              ))
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
}