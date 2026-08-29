import 'package:supabase_flutter/supabase_flutter.dart';

class WaterService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchWaterData(String dateStr) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final profile = await _supabase.from('users_profile').select('water_target_ml').eq('id', user.id).single();
    final waterData = await _supabase.from('daily_summaries').select('total_water_ml').eq('user_id', user.id).eq('date', dateStr).maybeSingle();

    return {
      'target': profile['water_target_ml'] ?? 2500,
      'consumed': waterData != null ? (waterData['total_water_ml'] ?? 0) : 0,
    };
  }

  Future<void> updateWater(String dateStr, int newTotal) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('daily_summaries').upsert({
      'user_id': user.id,
      'date': dateStr,
      'total_water_ml': newTotal
    }, onConflict: 'user_id,date');
  }
}