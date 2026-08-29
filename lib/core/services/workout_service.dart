import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchWorkoutData(String dateStr) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final profile = await _supabase.from('users_profile').select('weight_kg').eq('id', user.id).maybeSingle();
    final exercises = await _supabase.from('exercises').select('*').order('name', ascending: true);
    final logs = await _supabase.from('workout_logs')
        .select('id, duration_minutes, calories_burned, exercises(name)')
        .eq('user_id', user.id)
        .eq('date', dateStr)
        .order('created_at', ascending: true);

    return {
      'weight_kg': profile != null ? profile['weight_kg'] : 70.0,
      'exercises': exercises,
      'logs': logs,
    };
  }

  Future<void> addWorkout(int exerciseId, String dateStr, int duration, int calories) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('workout_logs').insert({
      'user_id': user.id,
      'exercise_id': exerciseId,
      'date': dateStr,
      'duration_minutes': duration,
      'calories_burned': calories,
    });
  }

  Future<void> deleteWorkout(String logId) async {
    await _supabase.from('workout_logs').delete().eq('id', logId);
  }
}