import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/app_localization.dart';

class AiFoodService {
  final _supabase = Supabase.instance.client;

  Future<List<String>> _getDynamicApiKeys() async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('config_value')
          .like('config_name', 'gemini_key_%')
          .eq('is_active', true)
          .order('config_name', ascending: true);

      List<String> keys = response.map<String>((row) => row['config_value'].toString()).toList();

      if (keys.isNotEmpty) {
        return keys;
      } else {
        return [dotenv.env['GEMINI_API_KEY']!];
      }
    } catch (e) {
      return [dotenv.env['GEMINI_API_KEY']!];
    }
  }

  Future<List<Map<String, dynamic>>> analyzeFoodsMulti({String? textInput, Uint8List? imageBytes}) async {

    final List<String> apiKeys = await _getDynamicApiKeys();

    final prompt = '''
    Tugasmu menganalisis makanan dari data yang diberikan (gambar dan/atau teks).
    Teks deskripsi dari pengguna: "${textInput?.isNotEmpty == true ? textInput : 'Tidak ada teks'}"
    
    ATURAN SANGAT PENTING (BACA DENGAN TELITI): 
    1. FILTER NON-MAKANAN: Periksa apakah gambar/teks BENAR-BENAR berisi objek makanan/minuman yang valid. Jika benda mati, orang, pemandangan, atau kosong, KEMBALIKAN JSON ARRAY KOSONG: []
    2. PENANGANAN PORSI/JUMLAH: JANGAN pernah memasukkan angka, satuan, atau jumlah porsi ke dalam "keyword". Nama makanan harus BERSIH. Masukkan porsi/jumlah HANYA ke dalam properti "quantity". (Contoh: Jika ada 5 potong ayam, keyword: "Ayam Goreng", quantity: 5.0).
    3. KONDISI KOMBO: Jika makanan gabungan (misal: "Mie Ayam Telur"), berikan output ganda:
       - OPSI KESATUAN: (misal: "Mie Ayam Telur").
       - OPSI PECAHAN: (misal: "Mie Ayam" dan "Telur").
    4. FORMAT NAMA (TITLE CASE): Perbaiki penulisan nama makanan pada "keyword" menjadi Title Case.
    5. REFERENSI DATA NUTRISI (WAJIB AKURAT): Estimasi nilai nutrisi HARUS didasarkan pada basis data publik.
    6. BOUNDING BOX: Berikan koordinat kotak deteksi dari makanan tersebut pada gambar.

    Untuk SETIAP item makanan yang valid, tentukan:
    1. "keyword": Nama makanan bersih tanpa atribut jumlah dalam format Title Case (Cth: "Sate Ayam").
    2. "quantity": Angka estimasi porsi/jumlahnya (Cth: 3.0).
    3. "fallback_cal": Total Estimasi kalori referensi valid (angka).
    4. "fallback_p": Total Estimasi protein referensi valid (g).
    5. "fallback_c": Total Estimasi karbohidrat referensi valid (g).
    6. "fallback_f": Total Estimasi lemak referensi valid (g).
    7. "box_2d": Array 4 angka [ymin, xmin, ymax, xmax] yang mewakili kotak deteksi dengan skala 0-1000. Jika tidak ada gambar, kembalikan [0,0,0,0].

    Kembalikan HANYA format JSON Array ketat tanpa awalan markdown. Contoh:
    [
      {
        "keyword": "Donat Coklat",
        "quantity": 5.0,
        "fallback_cal": 1250,
        "fallback_p": 15,
        "fallback_c": 150,
        "fallback_f": 60,
        "box_2d": [250, 100, 750, 900]
      }
    ]
    ''';

    for (int i = 0; i < apiKeys.length; i++) {
      final currentKey = apiKeys[i];
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: currentKey);

      try {
        GenerateContentResponse response;

        if (imageBytes != null) {
          response = await model.generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ])
          ]);
        } else {
          response = await model.generateContent([Content.text(prompt)]);
        }

        String cleanText = (response.text ?? '[]').replaceAll('```json', '').replaceAll('```', '').trim();

        List<dynamic> aiItems;
        try {
          aiItems = jsonDecode(cleanText);
        } catch (e) {
          aiItems = [];
        }

        List<Map<String, dynamic>> finalParsedItems = [];

        for (var item in aiItems) {
          String rawKeyword = item['keyword']?.toString().trim() ?? '';
          double qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;

          List<dynamic> boxRaw = item['box_2d'] ?? [0,0,0,0];
          List<double> box2d = boxRaw.map((e) => (e as num).toDouble()).toList();

          if (rawKeyword.isNotEmpty) {
            final res = await _supabase
                .from('foods')
                .select('id, name, calories, protein, carbs, fat')
                .ilike('name', '%$rawKeyword%')
                .order('name', ascending: true)
                .limit(5);

            Map<String, dynamic> fallbackItem = {
              'name': rawKeyword,
              'calories': (item['fallback_cal'] as num?)?.toDouble() ?? 0.0,
              'protein': (item['fallback_p'] as num?)?.toDouble() ?? 0.0,
              'carbs': (item['fallback_c'] as num?)?.toDouble() ?? 0.0,
              'fat': (item['fallback_f'] as num?)?.toDouble() ?? 0.0,
            };

            finalParsedItems.add({
              'keyword': rawKeyword,
              'quantity': qty,
              'matches': List<Map<String, dynamic>>.from(res),
              'fallback': fallbackItem,
              'box_2d': box2d,
            });
          }
        }

        return finalParsedItems;

      } catch (e) {
        String errorString = e.toString().toLowerCase();

        bool isQuotaError = errorString.contains('429') ||
            errorString.contains('quota') ||
            errorString.contains('exhausted') ||
            errorString.contains('rate limit');

        if (isQuotaError && i < apiKeys.length - 1) {
          print('Token ke-${i+1} habis. Beralih ke token cadangan...');
          continue;
        } else {
          if (isQuotaError) {
            throw Exception(tr('all_ai_tokens_exhausted'));
          } else {
            throw Exception('${tr('failed_process_ai')} $e');
          }
        }
      }
    }

    throw Exception(tr('unexpected_ai_error'));
  }
}