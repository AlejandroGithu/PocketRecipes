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
      version: 3, // Incrementamos la versión para soportar datos por usuario
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await _dropUserContentTables(db);
      await _createUserContentTables(db);
    }
  }

  Future _createDB(Database db, int version) async {
  const textType = 'TEXT NOT NULL';

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name $textType,
        email $textType UNIQUE,
        password $textType,
        createdAt TEXT NOT NULL
      )
    ''');

    await _createUserContentTables(db);
  }

  Future<void> _createUserContentTables(Database db) async {
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE favorites (
        id TEXT NOT NULL,
        userId INTEGER NOT NULL,
        name $textType,
        category $textTypeNullable,
        area $textTypeNullable,
        instructions $textTypeNullable,
        imageUrl $textType,
        youtubeUrl $textTypeNullable,
        tags $textTypeNullable,
        createdAt TEXT NOT NULL,
        PRIMARY KEY (id, userId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealId TEXT NOT NULL,
        userId INTEGER NOT NULL,
        ingredient TEXT NOT NULL,
        measure TEXT,
        FOREIGN KEY (mealId, userId) REFERENCES favorites (id, userId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_recipes (
        id TEXT NOT NULL,
        userId INTEGER NOT NULL,
        name $textType,
        description $textTypeNullable,
        imageUrl $textTypeNullable,
        time $textTypeNullable,
        servings $textTypeNullable,
        difficulty $textTypeNullable,
        createdAt TEXT NOT NULL,
        PRIMARY KEY (id, userId),
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        userId INTEGER NOT NULL,
        ingredient TEXT NOT NULL,
        measure TEXT,
        FOREIGN KEY (recipeId, userId) REFERENCES user_recipes (id, userId) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_recipe_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId TEXT NOT NULL,
        userId INTEGER NOT NULL,
        stepNumber INTEGER NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (recipeId, userId) REFERENCES user_recipes (id, userId) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _dropUserContentTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS favorite_ingredients');
    await db.execute('DROP TABLE IF EXISTS favorites');
    await db.execute('DROP TABLE IF EXISTS user_recipe_ingredients');
    await db.execute('DROP TABLE IF EXISTS user_recipe_steps');
    await db.execute('DROP TABLE IF EXISTS user_recipes');
  }

  // USUARIOS - LOGIN Y REGISTRO
  Future<Map<String, dynamic>?> registerUser(String name, String email, String password) async {
    final db = await instance.database;
    
    // Verificar si el email ya existe
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (existing.isNotEmpty) {
      return null; // Email ya registrado
    }
    
    final id = await db.insert('users', {
      'name': name,
      'email': email,
      'password': password, // En producción, deberías usar hash
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    
    if (result.isEmpty) {
      return null; // Credenciales incorrectas
    }
    
    return {
      'id': result.first['id'],
      'name': result.first['name'],
      'email': result.first['email'],
    };
  }

  // FAVORITOS
  Future<void> addFavorite(Meal meal, int userId) async {
    final db = await instance.database;
    
    await db.delete(
      'favorite_ingredients',
      where: 'mealId = ? AND userId = ?',
      whereArgs: [meal.id, userId],
    );

    await db.insert(
      'favorites',
      {
        'id': meal.id,
        'userId': userId,
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
        'userId': userId,
        'ingredient': entry.key,
        'measure': entry.value,
      });
    }
  }

  Future<void> removeFavorite(String mealId, int userId) async {
    final db = await instance.database;
    await db.delete(
      'favorites',
      where: 'id = ? AND userId = ?',
      whereArgs: [mealId, userId],
    );
    await db.delete(
      'favorite_ingredients',
      where: 'mealId = ? AND userId = ?',
      whereArgs: [mealId, userId],
    );
  }

  Future<bool> isFavorite(String mealId, int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'id = ? AND userId = ?',
      whereArgs: [mealId, userId],
    );
    return result.isNotEmpty;
  }

  Future<List<Meal>> getFavorites(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    List<Meal> favorites = [];
    for (var row in result) {
      final ingredients = await db.query(
        'favorite_ingredients',
        where: 'mealId = ? AND userId = ?',
        whereArgs: [row['id'], userId],
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
  Future<String> addUserRecipe(Map<String, dynamic> recipe, int userId) async {
    final db = await instance.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('user_recipes', {
      'id': id,
      'userId': userId,
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
          'userId': userId,
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
          'userId': userId,
          'stepNumber': stepNumber++,
          'description': step,
        });
      }
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> getUserRecipes(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_recipes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    List<Map<String, dynamic>> recipes = [];
    for (var row in result) {
      final ingredients = await db.query(
        'user_recipe_ingredients',
        where: 'recipeId = ? AND userId = ?',
        whereArgs: [row['id'], userId],
      );

      final steps = await db.query(
        'user_recipe_steps',
        where: 'recipeId = ? AND userId = ?',
        whereArgs: [row['id'], userId],
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

  Future<Map<String, dynamic>?> getUserRecipeById(String id, int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_recipes',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final ingredients = await db.query(
      'user_recipe_ingredients',
      where: 'recipeId = ? AND userId = ?',
      whereArgs: [id, userId],
    );

    final steps = await db.query(
      'user_recipe_steps',
      where: 'recipeId = ? AND userId = ?',
      whereArgs: [id, userId],
      orderBy: 'stepNumber',
    );

    return {
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
    };
  }

  Future<void> deleteUserRecipe(String id, int userId) async {
    final db = await instance.database;
    await db.delete(
      'user_recipes',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await db.delete(
      'user_recipe_ingredients',
      where: 'recipeId = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await db.delete(
      'user_recipe_steps',
      where: 'recipeId = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}