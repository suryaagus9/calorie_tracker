import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  // Fungsi mengecek apakah user sudah mengisi data Setup (Tinggi & Berat Badan)
  Future<bool> isProfileComplete() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final data = await _supabase.from('users_profile').select('weight_kg, height_cm').eq('id', user.id).maybeSingle();

      if (data == null || data['weight_kg'] == null || data['height_cm'] == null) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Mengambil data profil untuk ProfileScreen dan EditProfileScreen
  Future<Map<String, dynamic>> fetchProfileData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return await _supabase.from('users_profile').select().eq('id', user.id).single();
  }

  // Fungsi kalkulasi dan simpan dari GoalScreen (sebelumnya)
  Future<Map<String, dynamic>> calculateAndSaveProfile(Map<String, dynamic> profileData, int selectedGoal) async {
    return await _calculateMetricsAndSave(profileData['weight'].toString(), profileData['height'].toString(), profileData['gender'].toString(), profileData['dob'].toString(), profileData['activity_level'] as int? ?? 1, selectedGoal);
  }

  // Fungsi kalkulasi dan simpan dari EditProfileScreen
  Future<void> updateProfileAndMetrics(String weightStr, String heightStr, String gender, String dob, int activityLevel, int goal) async {
    await _calculateMetricsAndSave(weightStr, heightStr, gender, dob, activityLevel, goal);
  }

  // Logika Internal Kalkulator (BMR, BMI, TDEE)
  Future<Map<String, dynamic>> _calculateMetricsAndSave(String rawWeight, String rawHeight, String gender, String rawDob, int activityLevel, int goal) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final double weight = double.tryParse(rawWeight.replaceAll(',', '.')) ?? 70.0;
    final double height = double.tryParse(rawHeight.replaceAll(',', '.')) ?? 170.0;

    int age = 25;
    String formattedDob = rawDob;
    try {
      DateTime? birthDate;
      if (rawDob.contains('/')) {
        List<String> parts = rawDob.split('/');
        if (parts.length == 3) {
          formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
          birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (rawDob.contains('-')) {
        birthDate = DateTime.parse(rawDob);
      }
      if (birthDate != null) {
        DateTime today = DateTime.now();
        age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
      }
    } catch (_) {}

    double bmi = weight / ((height / 100) * (height / 100));
    double bmr = gender == 'Male' ? (10 * weight) + (6.25 * height) - (5 * age) + 5 : (10 * weight) + (6.25 * height) - (5 * age) - 161;

    double multiplier = 1.2;
    if (activityLevel == 1) multiplier = 1.375;
    else if (activityLevel == 2) multiplier = 1.55;
    else if (activityLevel == 3) multiplier = 1.725;

    double tdee = bmr * multiplier;
    if (goal == 0) tdee -= 500;
    if (goal == 2) tdee += 500;

    int waterTarget = (weight * 35).round();

    await _supabase.from('users_profile').update({
      'gender': gender, 'dob': formattedDob, 'weight_kg': weight, 'height_cm': height, 'activity_level': activityLevel, 'goal': goal, 'tdee_target': tdee.round(), 'water_target_ml': waterTarget,
    }).eq('id', user.id);

    return {'bmi': bmi, 'tdee': tdee.round(), 'age': age};
  }
}