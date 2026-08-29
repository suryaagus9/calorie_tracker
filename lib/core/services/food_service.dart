import 'package:supabase_flutter/supabase_flutter.dart';

class FoodService {
  final _supabase = Supabase.instance.client;

  Future<String> get _currentUserId async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.id;
  }

  // LOGIKA UNTUK FOOD LOG SCREEN
  Future<List<Map<String, dynamic>>> fetchTodayMeals(String dateStr) async {
    final uid = await _currentUserId;
    final data = await _supabase.from('meal_logs')
        .select('id, meal_type, calories_consumed, foods(name, calories)')
        .eq('user_id', uid).eq('date', dateStr).order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchQuickAddFoods() async {
    final uid = await _currentUserId;
    Set<String> hiddenIds = {};
    try {
      final hiddenRes = await _supabase.from('user_hidden_foods').select('food_id').eq('user_id', uid);
      hiddenIds = hiddenRes.map((e) => e['food_id'].toString()).toSet();
    } catch (_) {}

    final response = await _supabase.from('meal_logs')
        .select('foods(id, name, calories, protein, carbs, fat, created_by)')
        .eq('user_id', uid).order('created_at', ascending: false).limit(30);

    List<Map<String, dynamic>> validFoods = [];
    Set<String> uniqueIds = {};
    for (var row in response) {
      final food = row['foods'];
      if (food != null) {
        final idStr = food['id'].toString();
        if (!uniqueIds.contains(idStr) && !hiddenIds.contains(idStr)) {
          uniqueIds.add(idStr);
          validFoods.add(Map<String, dynamic>.from(food));
        }
      }
    }
    return validFoods;
  }

  Future<void> deleteMealLog(String logId) async {
    await _supabase.from('meal_logs').delete().eq('id', logId);
  }

  Future<void> updateMealLog(String logId, String mealType, int calories) async {
    await _supabase.from('meal_logs').update({
      'meal_type': mealType,
      'calories_consumed': calories,
    }).eq('id', logId);
  }

  // LOGIKA UNTUK ADD FOOD SCREEN
  Future<List<dynamic>> searchFoods(String query) async {
    final uid = await _currentUserId;
    Set<String> hiddenIds = {};
    try {
      final hiddenRes = await _supabase.from('user_hidden_foods').select('food_id').eq('user_id', uid);
      hiddenIds = hiddenRes.map((e) => e['food_id'].toString()).toSet();
    } catch (_) {}

    final response = await _supabase.from('foods')
        .select('id, name, calories, protein, carbs, fat, created_by')
        .ilike('name', '%$query%')
        .order('name', ascending: true).limit(50);

    return response.where((food) => !hiddenIds.contains(food['id'].toString())).toList();
  }

  Future<List<dynamic>> fetchRecentFoods(String query) async {
    final uid = await _currentUserId;
    Set<String> hiddenIds = {};
    try {
      final hiddenRes = await _supabase.from('user_hidden_foods').select('food_id').eq('user_id', uid);
      hiddenIds = hiddenRes.map((e) => e['food_id'].toString()).toSet();
    } catch (_) {}

    final response = await _supabase.from('meal_logs')
        .select('foods(id, name, calories, protein, carbs, fat, created_by)')
        .eq('user_id', uid).order('created_at', ascending: false).limit(50);

    Set<String> uniqueIds = {};
    List<dynamic> validRows = [];
    for (var row in response) {
      final food = row['foods'];
      if (food != null) {
        final idStr = food['id'].toString();
        if (!uniqueIds.contains(idStr) && !hiddenIds.contains(idStr)) {
          uniqueIds.add(idStr);
          final name = food['name'].toString().toLowerCase();
          if (query.isEmpty || name.contains(query.toLowerCase())) validRows.add(food);
        }
      }
    }
    return validRows;
  }

  Future<String> createCustomFood(String name, double cal, double p, double c, double f) async {
    final uid = await _currentUserId;
    final res = await _supabase.from('foods').insert({
      'name': name, 'calories': cal, 'protein': p, 'carbs': c, 'fat': f, 'created_by': uid, 'is_verified': false,
    }).select('id').single();
    return res['id'].toString();
  }

  Future<void> insertMealLog(String? foodId, String dateStr, String mealType, int calories) async {
    final uid = await _currentUserId;
    await _supabase.from('meal_logs').insert({
      'user_id': uid, 'food_id': foodId != null ? int.parse(foodId) : null, 'date': dateStr, 'meal_type': mealType, 'calories_consumed': calories,
    });
  }

  // LOGIKA UNTUK FOOD DETAIL SCREEN
  Future<void> updateFood(String foodId, String name, double cal, double p, double c, double f) async {
    await _supabase.from('foods').update({'name': name, 'calories': cal, 'protein': p, 'carbs': c, 'fat': f}).eq('id', int.parse(foodId));
  }

  Future<void> hideOrDeleteFood(String foodId, String creatorId) async {
    final uid = await _currentUserId;
    try {
      final existingData = await _supabase.from('user_hidden_foods').select('food_id').eq('user_id', uid).eq('food_id', int.parse(foodId));
      if (existingData.isEmpty) {
        await _supabase.from('user_hidden_foods').insert({
          'user_id': uid, 'food_id': int.parse(foodId), 'hidden_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    if (creatorId == uid) {
      try {
        await _supabase.from('foods').delete().eq('id', int.parse(foodId));
      } catch (_) {}
    }
  }
}