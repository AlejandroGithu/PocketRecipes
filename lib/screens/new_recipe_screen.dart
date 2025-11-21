import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewRecipeScreen extends StatefulWidget {
  const NewRecipeScreen({super.key});

  @override
  State<NewRecipeScreen> createState() => _NewRecipeScreenState();
}

class _NewRecipeScreenState extends State<NewRecipeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _ingredientNameController = TextEditingController();
  final TextEditingController _ingredientQuantityController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();

  final List<Map<String, String>> _ingredients = [];
  final List<String> _steps = [];
  final List<String> _unitOptions = [
    'g',
    'kg',
    'mg',
    'ml',
    'l',
    'cup',
    'tablespoon',
    'teaspoon',
    'piece',
    'serving',
  ];
  String _selectedDifficulty = 'Easy';
  String _selectedUnit = 'g';
  File? _selectedImage;

  String? _ingredientError;
  String? _servingsError;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    _ingredientNameController.dispose();
    _ingredientQuantityController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final name = _ingredientNameController.text.trim();
    final quantity = _ingredientQuantityController.text.trim();

    if (name.length < 3) {
      setState(() {
  _ingredientError = 'Ingredient name must be at least 3 letters';
      });
      return;
    }

    if (quantity.isEmpty) {
      setState(() {
  _ingredientError = 'Enter the quantity using numbers only';
      });
      return;
    }

    setState(() {
      _ingredients.add({
        'name': name,
        'quantity': quantity,
        'unit': _selectedUnit,
        'measure': '$quantity $_selectedUnit',
      });
      _ingredientNameController.clear();
      _ingredientQuantityController.clear();
      _ingredientError = null;
      _formError = null;
    });
  }

  void _addStep() {
    final stepText = _stepController.text.trim();

    if (stepText.isEmpty) {
      setState(() {
  _formError = 'Enter a step description before adding it.';
      });
      return;
    }

    setState(() {
      _steps.add(stepText);
      _stepController.clear();
      _formError = null;
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _ingredientError = null;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'recipe_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedPath = p.join(appDir.path, fileName);

      final savedImage = await File(pickedFile.path).copy(savedPath);

      if (!mounted) return;
      setState(() {
        _selectedImage = savedImage;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Could not load the image: $e')),
      );
    }
  }

  Future<void> _publishRecipe() async {
    final name = _nameController.text.trim();
    final servingsText = _servingsController.text.trim();

    setState(() {
      _formError = null;
      _servingsError = null;
    });

    if (name.length < 3) {
      setState(() {
  _formError = 'Recipe name must be at least 3 characters long.';
      });
      return;
    }

    if (servingsText.isEmpty) {
      setState(() {
  _servingsError = 'Enter the number of servings';
  _formError = 'Fix the highlighted fields before continuing.';
      });
      return;
    }

    final servingsValue = int.tryParse(servingsText);
    if (servingsValue == null || servingsValue <= 0) {
      setState(() {
  _servingsError = 'Enter a valid number of servings';
  _formError = 'Fix the highlighted fields before continuing.';
      });
      return;
    }

    if (_ingredients.isEmpty) {
      setState(() {
  _formError = 'Add at least one ingredient before publishing.';
      });
      return;
    }

    if (_steps.isEmpty) {
      setState(() {
  _formError = 'Add at least one preparation step.';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log in to publish recipes')),
        );
      }
      return;
    }

    try {
      await _dbHelper.addUserRecipe({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _selectedImage?.path,
        'time': _timeController.text.trim(),
        'servings': _servingsController.text.trim(),
        'difficulty': _selectedDifficulty,
        'ingredients': _ingredients,
        'steps': _steps,
      }, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe published successfully')),
        );
        setState(() {
          _formError = null;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing recipe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'New Recipe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Share your creation',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo upload area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 2, style: BorderStyle.solid),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.add_a_photo, color: Colors.white38, size: 48),
                      ),
                    if (_selectedImage == null)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Tap to upload photo (JPG or PNG)',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to change photo',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Recipe name
            const Text(
              'Recipe name',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: Classic Carbonara Pasta',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Description
            const Text(
              'Description',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe your recipe...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Time, Servings, Difficulty
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _timeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '30 min',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servings',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _servingsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: '4',
                          hintStyle: const TextStyle(color: Colors.white24),
                          errorText: _servingsError,
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Difficulty',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2A2A2A),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: ['Easy', 'Medium', 'Hard'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedDifficulty = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Ingredients
            const Text(
              'Ingredients',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex: Spaghetti pasta',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _ingredientQuantityController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Qty.',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedUnit,
                    dropdownColor: const Color(0xFF2A2A2A),
                    underline: const SizedBox(),
                    iconEnabledColor: Colors.white70,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedUnit = value;
                      });
                    },
                    items: _unitOptions
                        .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            if (_ingredientError != null) ...[
              const SizedBox(height: 8),
              Text(
                _ingredientError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add, color: Colors.white70),
              label: const Text(
                '+ Add Ingredient',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            // List of added ingredients
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ingredient['name']} - ${ingredient['measure']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () => _removeIngredient(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            // Preparation steps
            const Text(
              'Preparation steps',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
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
                      '${_steps.length + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ex: Boil salted water',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _addStep,
              icon: const Icon(Icons.add, color: Colors.white70),
              label: const Text(
                '+ Add Step',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            // List of added steps
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF404040),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                        onPressed: () => _removeStep(index),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
            if (_formError != null) ...[
              Text(
                _formError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _publishRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Publish',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}