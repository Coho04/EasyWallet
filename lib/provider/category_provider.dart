import 'package:flutter/foundation.dart';
import 'package:easy_wallet/model/category.dart' as category;
import 'package:easy_wallet/persistence_controller.dart';

class CategoryProvider with ChangeNotifier {
  List<category.Category> _categories = [];

  List<category.Category> get categories => _categories;

  Future<void> loadCategories() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      await PersistenceController.instance.syncWithCloud();
    }
    _categories = await category.Category.all();
    notifyListeners();
  }

  Future<void> saveCategory(category.Category category) async {
    await category.save();
    await loadCategories();
  }

  Future<void> deleteCategory(category.Category category) async {
    await category.delete();
    await loadCategories();
  }

  void callNotifyListeners() {
    notifyListeners();
  }
}
