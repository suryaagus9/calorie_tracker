import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchDashboardData(String dateStr) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final profileData = await _supabase.from('users_profile').select().eq('id', user.id).single();
    final mealsData = await _supabase.from('meal_logs').select('*, foods(name, calories, protein, carbs, fat)').eq('user_id', user.id).eq('date', dateStr);
    final waterData = await _supabase.from('daily_summaries').select().eq('user_id', user.id).eq('date', dateStr).maybeSingle();
    final workoutData = await _supabase.from('workout_logs').select('id, duration_minutes, calories_burned, exercises(name)').eq('user_id', user.id).eq('date', dateStr).order('created_at', ascending: true);

    return {
      'profile': profileData,
      'meals': mealsData,
      'water': waterData,
      'workouts': workoutData,
    };
  }

  Future<void> addWater(String dateStr, int newTotalAmount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('daily_summaries').upsert({
      'user_id': user.id,
      'date': dateStr,
      'total_water_ml': newTotalAmount
    }, onConflict: 'user_id,date');
  }
}