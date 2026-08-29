import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiFoodService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> analyzeFoodsMulti(String input) async {
    final String apiKey = dotenv.env['GEMINI_API_KEY']!;
    final model = GenerativeModel(model: 'gemini-3.5-flash-lite', apiKey: apiKey);

    try {
      // -------------------------------------------------------------
      // TAHAP 1: AI SEBAGAI PEMISAH DAN PENGGABUNG KALIMAT
      // -------------------------------------------------------------
      final prompt = '''
      Pengguna berkata: "$input".
      Tugasmu menganalisis dan memecah kalimat menjadi daftar makanan.
      
      ATURAN SANGAT PENTING: 
      Jika kalimat mengandung makanan gabungan atau kombo (misalnya: "Mie Ayam Telur", "Nasi Goreng Ayam", "Ayam Bakar Nasi"), kamu HARUS memberikan output ganda yang mencakup:
      1. OPSI KESATUAN: Makanan digabung menjadi satu kesatuan (misal: "Mie Ayam Telur").
      2. OPSI PECAHAN: Makanan dipecah menjadi komponen terpisah (misal: "Mie Ayam" dan "Telur").
      
      Jika pengguna hanya menyebutkan makanan tunggal (misal: "Apel"), berikan 1 output saja.

      Untuk SETIAP item (baik kesatuan maupun pecahan), tentukan:
      1. "keyword": Nama dasar makanan untuk pencarian database.
      2. "quantity": Jumlah porsi berupa angka (misal: 1.0 atau 2.0).
      3. "fallback_cal": Estimasi kalori 1 porsi (angka).
      4. "fallback_p": Estimasi protein 1 porsi (g).
      5. "fallback_c": Estimasi karbohidrat 1 porsi (g).
      6. "fallback_f": Estimasi lemak 1 porsi (g).

      Kembalikan HANYA format JSON Array ketat tanpa awalan markdown:
      [
        {
          "keyword": "Mie Ayam Telur",
          "quantity": 1.0,
          "fallback_cal": 500,
          "fallback_p": 20,
          "fallback_c": 50,
          "fallback_f": 15
        },
        {
          "keyword": "Mie Ayam",
          "quantity": 1.0,
          "fallback_cal": 420,
          "fallback_p": 14,
          "fallback_c": 45,
          "fallback_f": 10
        },
        {
          "keyword": "Telur",
          "quantity": 1.0,
          "fallback_cal": 80,
          "fallback_p": 6,
          "fallback_c": 5,
          "fallback_f": 5
        }
      ]
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      String cleanText = (response.text ?? '[]').replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> aiItems;
      try {
        aiItems = jsonDecode(cleanText);
      } catch (e) {
        aiItems = [];
      }

      List<Map<String, dynamic>> finalParsedItems = [];

      // -------------------------------------------------------------
      // TAHAP 2: CARI KECOCOKAN DI DATABASE (Ambil top 5)
      // -------------------------------------------------------------
      for (var item in aiItems) {
        String keyword = item['keyword']?.toString().trim() ?? '';
        double qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;

        if (keyword.isNotEmpty) {
          final res = await _supabase
              .from('foods')
              .select('id, name, calories, protein, carbs, fat')
              .ilike('name', '%$keyword%')
              .order('name', ascending: true)
              .limit(5); // Ambil 5 varian untuk dipilih user

          finalParsedItems.add({
            'keyword': keyword,
            'quantity': qty,
            'matches': List<Map<String, dynamic>>.from(res),
            'fallback': {
              'name': keyword,
              'calories': (item['fallback_cal'] as num?)?.toDouble() ?? 0.0,
              'protein': (item['fallback_p'] as num?)?.toDouble() ?? 0.0,
              'carbs': (item['fallback_c'] as num?)?.toDouble() ?? 0.0,
              'fat': (item['fallback_f'] as num?)?.toDouble() ?? 0.0,
            }
          });
        }
      }

      return finalParsedItems;
    } catch (e) {
      throw Exception('Gagal memproses AI: $e');
    }
  }
}