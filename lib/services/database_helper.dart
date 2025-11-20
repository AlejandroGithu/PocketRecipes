import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocket_recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    // Tabla de recetas favoritas
    await db.execute('''
      CREATE TABLE favorites (
        id $idType,
        name $textType,
        category $textTypeNullable,
        area $textTypeNullable,
        instructions $textTypeNullable,
        imageUrl $textType,
        youtubeUrl $textTypeNullable,
        tags $textTypeNullable,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabla de ingredientes de favoritos
    await db.execute('''
      CREATE TABLE favorite_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealId TEXT NOT NULL,
        ingredient TEXT NOT NULL,
        measure TEXT,
        FOREIGN KEY (mealId) REFERENCES favorites (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de recetas del usuario
    await db.execute('''
      CREATE TABLE user_recipes (
        id TEXT PRIMARY KEY,
        name $textType,
        description $textTypeNullable,
        imageUrl $textTypeNullable,
        time $textTypeNullable,
        servings $textTypeNullable,
        difficulty $textTypeNullable,
        createdAt TEXT NOT NULL
      )
    ''');

    // Tabla de ingredientes de recetas del usuario
    await db.execute('''
      CREATE TABLE user_recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        ingredient TEXT NOT NULL,
        measure TEXT,
        FOREIGN KEY (recipeId) REFERENCES user_recipes (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de pasos de recetas del usuario
    await db.execute('''
      CREATE TABLE user_recipe_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        stepNumber INTEGER NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES user_recipes (id) ON DELETE CASCADE
      )
    ''');
  }

  // FAVORITOS
  Future<void> addFavorite(Meal meal) async {
    final db = await instance.database;
    
    await db.insert(
      'favorites',
      {
        'id': meal.id,
        'name': meal.name,
        'category': meal.category,
        'area': meal.area,
        'instructions': meal.instructions,
        'imageUrl': meal.imageUrl,
        'youtubeUrl': meal.youtubeUrl,
        'tags': meal.tags,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insertar ingredientes
    for (var entry in meal.ingredients.entries) {
      await db.insert('favorite_ingredients', {
        'mealId': meal.id,
        'ingredient': entry.key,
        'measure': entry.value,
      });
    }
  }

  Future<void> removeFavorite(String mealId) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [mealId]);
    await db.delete('favorite_ingredients', where: 'mealId = ?', whereArgs: [mealId]);
  }

  Future<bool> isFavorite(String mealId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [mealId],
    );
    return result.isNotEmpty;
  }

  Future<List<Meal>> getFavorites() async {
    final db = await instance.database;
    final result = await db.query('favorites', orderBy: 'createdAt DESC');

    List<Meal> favorites = [];
    for (var row in result) {
      final ingredients = await db.query(
        'favorite_ingredients',
        where: 'mealId = ?',
        whereArgs: [row['id']],
      );

      Map<String, String> ingredientsMap = {};
      for (var ing in ingredients) {
        ingredientsMap[ing['ingredient'] as String] = ing['measure'] as String? ?? '';
      }

      favorites.add(Meal(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String?,
        area: row['area'] as String?,
        instructions: row['instructions'] as String?,
        imageUrl: row['imageUrl'] as String,
        youtubeUrl: row['youtubeUrl'] as String?,
        tags: row['tags'] as String?,
        ingredients: ingredientsMap,
      ));
    }

    return favorites;
  }

  // RECETAS DEL USUARIO
  Future<String> addUserRecipe(Map<String, dynamic> recipe) async {
    final db = await instance.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('user_recipes', {
      'id': id,
      'name': recipe['name'],
      'description': recipe['description'],
      'imageUrl': recipe['imageUrl'],
      'time': recipe['time'],
      'servings': recipe['servings'],
      'difficulty': recipe['difficulty'],
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Insertar ingredientes
    if (recipe['ingredients'] != null) {
      for (var ingredient in recipe['ingredients'] as List) {
        await db.insert('user_recipe_ingredients', {
          'recipeId': id,
          'ingredient': ingredient['name'],
          'measure': ingredient['measure'],
        });
      }
    }

    // Insertar pasos
    if (recipe['steps'] != null) {
      int stepNumber = 1;
      for (var step in recipe['steps'] as List) {
        await db.insert('user_recipe_steps', {
          'recipeId': id,
          'stepNumber': stepNumber++,
          'description': step,
        });
      }
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> getUserRecipes() async {
    final db = await instance.database;
    final result = await db.query('user_recipes', orderBy: 'createdAt DESC');

    List<Map<String, dynamic>> recipes = [];
    for (var row in result) {
      final ingredients = await db.query(
        'user_recipe_ingredients',
        where: 'recipeId = ?',
        whereArgs: [row['id']],
      );

      final steps = await db.query(
        'user_recipe_steps',
        where: 'recipeId = ?',
        whereArgs: [row['id']],
        orderBy: 'stepNumber',
      );

      recipes.add({
        'id': row['id'],
        'name': row['name'],
        'description': row['description'],
        'imageUrl': row['imageUrl'],
        'time': row['time'],
        'servings': row['servings'],
        'difficulty': row['difficulty'],
        'createdAt': row['createdAt'],
        'ingredients': ingredients,
        'steps': steps,
      });
    }

    return recipes;
  }

  Future<void> deleteUserRecipe(String id) async {
    final db = await instance.database;
    await db.delete('user_recipes', where: 'id = ?', whereArgs: [id]);
    await db.delete('user_recipe_ingredients', where: 'recipeId = ?', whereArgs: [id]);
    await db.delete('user_recipe_steps', where: 'recipeId = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}