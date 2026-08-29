import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchProgressData(List<String> dates) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final meals = await _supabase.from('meal_logs')
        .select('date, calories_consumed')
        .eq('user_id', user.id)
        .inFilter('date', dates);

    final workouts = await _supabase.from('workout_logs')
        .select('date, duration_minutes, calories_burned')
        .eq('user_id', user.id)
        .inFilter('date', dates);

    final water = await _supabase.from('daily_summaries')
        .select('date, total_water_ml')
        .eq('user_id', user.id)
        .inFilter('date', dates);

    return {
      'meals': meals,
      'workouts': workouts,
      'water': water,
    };
  }
}