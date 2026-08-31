import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static final ValueNotifier<String> currentLocale = ValueNotifier<String>('en');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      currentLocale.value = savedLang;
    }
  }

  static Future<void> changeLocale(String langCode) async {
    currentLocale.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'cancel': 'Cancel', 'save': 'Save', 'save_changes': 'Save Changes', 'failed': 'Failed', 'success': 'Success', 'unknown': 'Unknown', 'continue_btn': 'Continue', 'all': 'All', 'recent': 'Recent', 'remove': 'Remove', 'today': 'Today',

      // Profile
      'profile': 'Profile', 'age': 'AGE', 'kg': 'KG', 'cm': 'CM', 'body_metrics': 'Body Metrics', 'daily_target': 'Daily target', 'activity_level': 'Activity level', 'current_goal': 'Current goal', 'app_settings': 'APP SETTINGS', 'app_theme': 'App Theme', 'theme_desc': 'System, Light, or Dark', 'system': 'System', 'light': 'Light', 'dark': 'Dark', 'language': 'Language', 'english': 'English', 'indonesian': 'Indonesian', 'account': 'ACCOUNT', 'edit_profile': 'Edit Profile', 'edit_profile_desc': 'Personal data, goals', 'logout': 'Logout', 'logout_confirm_title': 'Logout', 'logout_confirm_desc': 'Are you sure you want to log out of your account?',

      // Status & Goals
      'underweight': 'Underweight', 'normal_weight': 'Normal weight', 'overweight': 'Overweight', 'obesity': 'Obesity', 'sedentary': 'Sedentary', 'lightly_active': 'Lightly Active', 'moderate_active': 'Moderate Active', 'very_active': 'Very Active', 'lose_weight': 'Lose Weight', 'maintain_weight': 'Maintain Weight', 'gain_muscle': 'Gain Muscle', 'cutting': 'Cutting', 'maintain': 'Maintain', 'bulking': 'Bulking',

      // Dashboard & Log
      'hello': 'Hello', 'todays_calories': "Today's Calories", 'of': 'of', 'kcal': 'kcal', 'remaining': 'remaining', 'calories': 'Calories', 'protein': 'Protein', 'carbs': 'Carbs', 'fat': 'Fat', 'water_intake': 'Water Intake', 'ml': 'ml', 'quick_actions': 'Quick Actions', 'add_food': 'Add Food', 'add_water': 'Add Water', 'workout': 'Workout', 'todays_meals': "Today's Meals", 'no_meals_today': 'No meals added yet today.', 'todays_workouts': "Today's Workouts", 'no_workouts_today': 'No workouts logged yet today.', 'exercises': 'Exercises', 'breakfast': 'Breakfast', 'lunch': 'Lunch', 'dinner': 'Dinner', 'snack': 'Snack', 'custom_food': 'Custom Food', 'food_log': 'Food Log', 'search_add_food': 'Search and add your food', 'search_food': 'Search food...', 'quick_add': 'Quick Add', 'no_recent_meals': 'Your recently added meals will appear here.', 'see_all_food': 'See All Food', 'track_hydration': 'Track daily hydration', 'daily_total': 'Daily Total', 'edit_log': 'Edit Log', 'adjust_portion_time': 'Adjust portion and time for all these foods', 'portion': 'portion(s)', 'log_updated': 'Log successfully updated!',

      // Add Food & Detail
      'ask_ai': 'Ask AI: "Ate 2 plates of fried rice..."', 'search_food_manually': 'Search food manually...', 'food_not_found': 'Food not found', 'item_selected': 'Item(s) Selected', 'create_custom_food': 'Create Custom Food', 'food_name': 'Food Name', 'calories_kcal': 'Calories (Kcal)', 'protein_g': 'Protein (g)', 'carbs_g': 'Carbs (g)', 'fat_g': 'Fat (g)', 'create_food': 'Create Food', 'fill_name_calories': 'Please fill in name and calories', 'custom_food_saved': 'Custom food saved!', 'failed_create_custom_food': 'Failed to create custom food', 'cannot_process_food': 'Cannot process this food.', 'ai_verification_result': 'AI Verification Result', 'choose_accurate_variant': 'Choose the most accurate food variant from the database', 'ai_detected': 'AI detected:', 'use_ai_estimation': 'Use AI Estimation', 'confirm_selection': 'Confirm Selection', 'adjust_food_log': 'Adjust Food Log', 'check_portion_time': 'Check portion and meal time for each item', 'save_items_to_log': 'Save Item(s) to Log', 'successfully_added_log': 'Successfully added to Log!', 'food_detail': 'Food Detail', 'remove_food': 'Remove Food', 'remove_food_confirm': 'Are you sure you want to remove this food from your view?', 'nutritional_information': 'Nutritional Information', 'total_per_serving': 'Total Per Serving', 'meal_type': 'Meal Type', 'number_of_servings': 'Number of Servings', 'serving_standard': '1 Serving = Standard Serving', 'add_to_log': 'Add to Log', 'food_updated': 'Food successfully updated!', 'food_removed': 'Food removed from your list!', 'added_to': 'added to',

      // AI & Smart Scanner
      'ai_analyzing': 'AI is analyzing...',
      'scanning_nutrition': 'Scanning nutrition from your plate 🍽️',
      'new_ai_badge': '✨ New (AI)',

      // Water Tracker
      'water_tracker': 'Water Tracker', 'reset_todays_water': 'Reset Today\'s Water', 'small_glass': 'small glass', 'regular_glass': 'regular glass', 'bottle': 'bottle', 'custom_amount': 'Custom Amount', 'add_custom_amount': 'Add Custom Amount',

      // Workout
      'track_and_log_exercises': 'Track and log your exercises', 'calories_burned_today': 'Calories Burned Today', 'h': 'h', 'min': 'min', 'categories': 'CATEGORIES', 'cardio': 'Cardio', 'run_cycling': 'Run, Cycling', 'strength': 'Strength', 'weightlifting': 'Weightlifting', 'stretching': 'Stretching', 'yoga': 'Yoga', 'sports': 'Sports', 'football_basket': 'Football, Basket', 'select_exercise': 'Select Exercise', 'category': 'Category', 'find_exercise': 'Find an exercise...', 'no_exercises_found': 'No exercises found.', 'duration_minutes': 'Duration (minutes)', 'estimated_burn': 'Estimated Burn', 'save_workout': 'Save Workout',

      // Progress
      'progress': 'Progress', 'track_milestones': 'Track your milestones', 'week': 'Week', 'month': 'Month', 'year': 'Year', 'last_7_days': 'Last 7 days', 'last_4_weeks': 'Last 4 weeks', 'last_6_months': 'Last 6 months', 'calories_consumed': 'Calories Consumed', 'calories_burned': 'Calories Burned', 'workouts_duration': 'Workouts Duration', 'last_7_days_summary': 'Last 7 Days Summary', 'avg_calories': 'Avg Calories', 'kcal_day': 'kcal/day', 'avg_water': 'Avg Water', 'ml_day': 'ml/day', 'kcal_week': 'kcal/week', 'this_week': 'this week',

      // Auth (Login & Register)
      'sign_in': 'Sign in', 'sign_in_continue': 'Sign in to continue your journey', 'email': 'Email', 'password': 'Password', 'forgot_password': 'Forgot Password?', 'or': 'or', 'sign_in_google': 'Sign in with Google', 'dont_have_account': 'Don\'t have an account? ', 'sign_up': 'Sign up', 'email_required': 'Email is required', 'invalid_email': 'Please enter a valid email address', 'password_required': 'Password is required', 'no_internet': 'No internet connection. Please check your network and try again.', 'wrong_credentials': 'The email or password you entered is incorrect.', 'login_failed': 'Login failed:', 'google_signin_failed': 'Google Sign-In failed:', 'reset_password': 'Reset Password', 'reset_password_desc': 'Enter your email address to receive a password reset link.', 'send_link': 'Send Link', 'reset_link_sent': 'Reset link sent! Please check your email inbox.', 'failed_send_link': 'Failed to send reset link:', 'update_password': 'Update Password', 'update_password_desc': 'Please enter your new secure password.', 'new_password': 'New password', 'password_min_length': 'Password must be at least 6 characters long.', 'password_updated': 'Password updated successfully! Redirecting...', 'failed_update_password': 'Failed to update password:', 'back': 'Back', 'create_account': 'Create Account', 'start_tracking': 'Start tracking your nutrition today', 'full_name': 'Full Name', 'your_name': 'Your name', 'confirm_password': 'Confirm Password', 'name_required': 'Full name is required', 'confirm_password_required': 'Please confirm your password', 'passwords_not_match': 'Passwords do not match', 'email_already_registered': 'This email is already registered. Please use another email or log in.', 'signup_failed': 'Registration failed:', 'signup_google': 'Sign up with Google',

      // Edit Profile
      'personal_data': 'PERSONAL DATA', 'date_of_birth': 'Date of Birth', 'email_address': 'Email Address', 'contact_support': 'Contact support to change email.', 'updating_your': 'Updating your ', 'weight_height_activity': 'weight, height, activity level, ', 'or_goal': 'or ', 'goal_will': 'goal ', 'auto_recalculate': 'will automatically recalculate your BMI and Daily Calorie Target (TDEE).', 'profile_updated': 'Profile successfully updated!',

      // Error & Validations
      'failed_load_history': 'Failed to load food history.',
      'check_internet': 'Please check your internet connection.',
      'fill_all_fields': 'Please fill in all fields.',
      'invalid_weight_height': 'Please enter valid weight (kg) and height (cm) numbers.',
      'failed_load_data_pull': 'Failed to load data. Pull down to refresh.',
      'remove_unnecessary_options': 'Remove the unnecessary options, then confirm.',
      'failed_open_media': 'Failed to open media: ',
      'ai_not_detected_error': 'Image/text not detected as food or drink. Please try again with a clearer photo.',
      'failed_process_ai': 'Failed to process AI: ',
    },
    'id': {
      // General
      'cancel': 'Batal', 'save': 'Simpan', 'save_changes': 'Simpan Perubahan', 'failed': 'Gagal', 'success': 'Berhasil', 'unknown': 'Tidak diketahui', 'continue_btn': 'Lanjut', 'all': 'Semua', 'recent': 'Terakhir', 'remove': 'Hapus', 'today': 'Hari Ini',

      // Profile
      'profile': 'Profil', 'age': 'UMUR', 'kg': 'KG', 'cm': 'CM', 'body_metrics': 'Metrik Tubuh', 'daily_target': 'Target harian', 'activity_level': 'Tingkat aktivitas', 'current_goal': 'Tujuan saat ini', 'app_settings': 'PENGATURAN APLIKASI', 'app_theme': 'Tema Aplikasi', 'theme_desc': 'Sistem, Terang, Gelap', 'system': 'Sistem', 'light': 'Terang', 'dark': 'Gelap', 'language': 'Bahasa', 'english': 'Inggris', 'indonesian': 'Indonesia', 'account': 'AKUN', 'edit_profile': 'Edit Profil', 'edit_profile_desc': 'Data pribadi, tujuan', 'logout': 'Keluar', 'logout_confirm_title': 'Keluar', 'logout_confirm_desc': 'Apakah Anda yakin ingin keluar dari akun Anda?',

      // Status & Goals
      'underweight': 'Kekurangan berat', 'normal_weight': 'Berat normal', 'overweight': 'Kelebihan berat', 'obesity': 'Obesitas', 'sedentary': 'Jarang Bergerak', 'lightly_active': 'Sedikit Aktif', 'moderate_active': 'Cukup Aktif', 'very_active': 'Sangat Aktif', 'lose_weight': 'Turunkan Berat', 'maintain_weight': 'Jaga Berat', 'gain_muscle': 'Tambah Otot', 'cutting': 'Menurunkan', 'maintain': 'Menjaga', 'bulking': 'Menaikkan',

      // Dashboard & Log
      'hello': 'Halo', 'todays_calories': "Kalori Hari Ini", 'of': 'dari', 'kcal': 'kcal', 'remaining': 'tersisa', 'calories': 'Kalori', 'protein': 'Protein', 'carbs': 'Karbo', 'fat': 'Lemak', 'water_intake': 'Asupan Air', 'ml': 'ml', 'quick_actions': 'Aksi Cepat', 'add_food': 'Tambah Makanan', 'add_water': 'Tambah Air', 'workout': 'Olahraga', 'todays_meals': "Makan Hari Ini", 'no_meals_today': 'Belum ada makanan dicatat hari ini.', 'todays_workouts': "Olahraga Hari Ini", 'no_workouts_today': 'Belum ada olahraga dicatat hari ini.', 'exercises': 'Latihan', 'breakfast': 'Sarapan', 'lunch': 'Makan Siang', 'dinner': 'Makan Malam', 'snack': 'Cemilan', 'custom_food': 'Makanan Kustom', 'food_log': 'Log Makanan', 'search_add_food': 'Cari dan tambahkan makanan', 'search_food': 'Cari makanan...', 'quick_add': 'Tambah Cepat', 'no_recent_meals': 'Makanan yang baru ditambahkan akan muncul di sini.', 'see_all_food': 'Lihat Semua Makanan', 'track_hydration': 'Lacak hidrasi harian', 'daily_total': 'Total Harian', 'edit_log': 'Edit Log', 'adjust_portion_time': 'Sesuaikan porsi dan waktu', 'portion': 'porsi', 'log_updated': 'Log berhasil diperbarui!',

      // Add Food & Detail
      'ask_ai': 'Tanya AI: "Makan 2 mangkok bakso..."', 'search_food_manually': 'Cari makanan manual...', 'food_not_found': 'Makanan tidak ditemukan', 'item_selected': 'Item Terpilih', 'create_custom_food': 'Buat Makanan Kustom', 'food_name': 'Nama Makanan', 'calories_kcal': 'Kalori (Kcal)', 'protein_g': 'Protein (g)', 'carbs_g': 'Karbo (g)', 'fat_g': 'Lemak (g)', 'create_food': 'Buat Makanan', 'fill_name_calories': 'Isi nama dan kalori', 'custom_food_saved': 'Makanan kustom tersimpan!', 'failed_create_custom_food': 'Gagal membuat makanan kustom', 'cannot_process_food': 'Tidak dapat memproses makanan ini.', 'ai_verification_result': 'Hasil Verifikasi AI', 'choose_accurate_variant': 'Pilih varian yang paling tepat dari database', 'ai_detected': 'AI mendeteksi:', 'use_ai_estimation': 'Gunakan Estimasi AI', 'confirm_selection': 'Konfirmasi Pilihan', 'adjust_food_log': 'Atur Log Makanan', 'check_portion_time': 'Periksa porsi dan jadwal makan', 'save_items_to_log': 'Simpan Item ke Log', 'successfully_added_log': 'Berhasil ditambahkan ke Log!', 'food_detail': 'Detail Makanan', 'remove_food': 'Hapus Makanan', 'remove_food_confirm': 'Yakin ingin menghapus makanan ini dari daftar Anda?', 'nutritional_information': 'Informasi Gizi', 'total_per_serving': 'Total Per Porsi', 'meal_type': 'Waktu Makan', 'number_of_servings': 'Jumlah Porsi', 'serving_standard': '1 Porsi = Porsi Standar', 'add_to_log': 'Tambah ke Log', 'food_updated': 'Makanan berhasil diperbarui!', 'food_removed': 'Makanan dihapus dari daftar Anda!', 'added_to': 'ditambahkan ke',

      // AI & Smart Scanner
      'ai_analyzing': 'AI sedang menganalisis...',
      'scanning_nutrition': 'Memindai nutrisi dari piringmu 🍽️',
      'new_ai_badge': '✨ Baru (AI)',

      // Water Tracker
      'water_tracker': 'Pelacak Air', 'reset_todays_water': 'Reset Air Hari Ini', 'small_glass': 'gelas kecil', 'regular_glass': 'gelas sedang', 'bottle': 'botol', 'custom_amount': 'Jumlah Kustom', 'add_custom_amount': 'Tambah Jumlah',

      // Workout
      'track_and_log_exercises': 'Lacak dan catat latihan Anda', 'calories_burned_today': 'Kalori Terbakar Hari Ini', 'h': 'j', 'min': 'mnt', 'categories': 'KATEGORI', 'cardio': 'Kardio', 'run_cycling': 'Lari, Sepeda', 'strength': 'Kekuatan', 'weightlifting': 'Angkat Beban', 'stretching': 'Peregangan', 'yoga': 'Yoga', 'sports': 'Olahraga', 'football_basket': 'Sepakbola, Basket', 'select_exercise': 'Pilih Latihan', 'category': 'Kategori', 'find_exercise': 'Cari latihan...', 'no_exercises_found': 'Latihan tidak ditemukan.', 'duration_minutes': 'Durasi (menit)', 'estimated_burn': 'Estimasi Terbakar', 'save_workout': 'Simpan Latihan',

      // Progress
      'progress': 'Progres', 'track_milestones': 'Pantau pencapaian Anda', 'week': 'Minggu', 'month': 'Bulan', 'year': 'Tahun', 'last_7_days': '7 hari terakhir', 'last_4_weeks': '4 minggu terakhir', 'last_6_months': '6 bulan terakhir', 'calories_consumed': 'Kalori Masuk', 'calories_burned': 'Kalori Terbakar', 'workouts_duration': 'Durasi Olahraga', 'last_7_days_summary': 'Ringkasan 7 Hari Terakhir', 'avg_calories': 'Rata-rata Kalori', 'kcal_day': 'kcal/hari', 'avg_water': 'Rata-rata Air', 'ml_day': 'ml/hari', 'kcal_week': 'kcal/minggu', 'this_week': 'minggu ini',

      // Auth (Login & Register)
      'sign_in': 'Masuk', 'sign_in_continue': 'Masuk untuk melanjutkan perjalanan Anda', 'email': 'Email', 'password': 'Kata Sandi', 'forgot_password': 'Lupa Kata Sandi?', 'or': 'atau', 'sign_in_google': 'Masuk dengan Google', 'dont_have_account': 'Belum punya akun? ', 'sign_up': 'Daftar', 'email_required': 'Email wajib diisi', 'invalid_email': 'Masukkan alamat email yang valid', 'password_required': 'Kata sandi wajib diisi', 'no_internet': 'Tidak ada koneksi internet. Silakan periksa jaringan Anda dan coba lagi.', 'wrong_credentials': 'Email atau kata sandi yang Anda masukkan salah.', 'login_failed': 'Login gagal:', 'google_signin_failed': 'Google Sign-In gagal:', 'reset_password': 'Reset Kata Sandi', 'reset_password_desc': 'Masukkan alamat email Anda untuk menerima tautan reset kata sandi.', 'send_link': 'Kirim Tautan', 'reset_link_sent': 'Tautan reset terkirim! Silakan periksa kotak masuk email Anda.', 'failed_send_link': 'Gagal mengirim tautan reset:', 'update_password': 'Perbarui Kata Sandi', 'update_password_desc': 'Silakan masukkan kata sandi baru Anda yang aman.', 'new_password': 'Kata sandi baru', 'password_min_length': 'Kata sandi minimal harus 6 karakter.', 'password_updated': 'Kata sandi berhasil diperbarui! Mengalihkan...', 'failed_update_password': 'Gagal memperbarui kata sandi:', 'back': 'Kembali', 'create_account': 'Buat Akun', 'start_tracking': 'Mulai lacak nutrisi Anda hari ini', 'full_name': 'Nama Lengkap', 'your_name': 'Nama Anda', 'confirm_password': 'Konfirmasi Kata Sandi', 'name_required': 'Nama lengkap wajib diisi', 'confirm_password_required': 'Harap konfirmasi kata sandi Anda', 'passwords_not_match': 'Kata sandi tidak cocok', 'email_already_registered': 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.', 'signup_failed': 'Registrasi gagal:', 'signup_google': 'Daftar dengan Google',

      // Edit Profile
      'personal_data': 'DATA PRIBADI', 'date_of_birth': 'Tanggal Lahir', 'email_address': 'Alamat Email', 'contact_support': 'Hubungi dukungan untuk mengubah email.', 'updating_your': 'Memperbarui ', 'weight_height_activity': 'berat, tinggi, tingkat aktivitas, ', 'or_goal': 'atau ', 'goal_will': 'tujuan ', 'auto_recalculate': 'akan secara otomatis menghitung ulang BMI dan Target Kalori Harian (TDEE) Anda.', 'profile_updated': 'Profil berhasil diperbarui!',

      // Error & Validations
      'failed_load_history': 'Gagal memuat riwayat makanan.',
      'check_internet': 'Periksa koneksi internet Anda.',
      'fill_all_fields': 'Tolong isi semua bidang dengan lengkap.',
      'invalid_weight_height': 'Tolong masukkan angka berat (kg) dan tinggi badan (cm) yang valid.',
      'failed_load_data_pull': 'Gagal memuat data. Tarik ke bawah untuk memuat ulang.',
      'remove_unnecessary_options': 'Hapus opsi yang tidak dibutuhkan, lalu konfirmasi.',
      'failed_open_media': 'Gagal membuka media: ',
      'ai_not_detected_error': 'Gambar/teks tidak terdeteksi sebagai makanan atau minuman. Silakan coba lagi dengan foto yang lebih jelas.',
      'failed_process_ai': 'Gagal memproses AI: ',
    }
  };

  static String tr(String key) {
    return _translations[currentLocale.value]?[key] ?? key;
  }
}

String tr(String key) => AppLocalizations.tr(key);