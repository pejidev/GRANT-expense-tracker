// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/recipes.dart';
//
// class RecipesViewModel extends ChangeNotifier {
//   List<Recipes> recipes = [];
//   final supabase = Supabase.instance.client;
//
//   // Fetch all contacts from the "contacts" table
//   Future<void> fetchRecipes() async {
//     try {
//       final data = await supabase.from('recipes').select();
//       recipes =
//           (data as List)
//               .map((recipesMap) => Recipes.fromMap(recipesMap))
//               .toList();
//       notifyListeners();
//     } catch (error) {
//       print('Error fetching contacts: $error');
//     }
//   }
//
//   // Create a new contact
//   Future<void> addRecipes(Recipes recipes) async {
//     try {
//       await supabase.from('recipes').insert(recipes.toMap());
//       await fetchRecipes();
//     } catch (error) {
//       print('Error adding contact: $error');
//     }
//   }
//
//   // Update an existing contact
//   Future<void> updateRecipes(Recipes recipes) async {
//     try {
//       await supabase
//           .from('recipes')
//           .update(recipes.toMap())
//           .eq('id', recipes.id!);
//       await fetchRecipes();
//     } catch (error) {
//       print('Error updating contact: $error');
//     }
//   }
//
//   // Delete a contact
//   Future<void> deleteRecipes(int id) async {
//     try {
//       await supabase.from('recipes').delete().eq('id', id);
//       await fetchRecipes();
//     } catch (error) {
//       print('Error deleting contact: $error');
//     }
//   }
// }
