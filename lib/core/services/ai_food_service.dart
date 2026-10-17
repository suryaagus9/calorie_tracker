import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_localization.dart';

class AiFoodService {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> analyzeFoodsMulti({String? textInput, Uint8List? imageBytes}) async {
    try {
      String? base64Image;
      if (imageBytes != null) {
        base64Image = base64Encode(imageBytes);
      }

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
      5. REFERENSI DATA NUTRISI (WAJIB AKURAT & TERPRIORITAS): Estimasi nilai nutrisi HARUS menggunakan urutan prioritas sumber basis data berikut:
         - PRIORITAS UTAMA: Gunakan data makronutrisi dari TKPI (Tabel Komposisi Pangan Indonesia) atau FatSecret.
         - PRIORITAS KEDUA: Jika makanan tidak ditemukan pada kedua sumber tersebut, gunakan basis data nutrisi publik lain yang benar-benar valid secara saintifik (seperti USDA). Jangan menebak secara sembarangan.      
      6. BOUNDING BOX: Berikan koordinat kotak deteksi dari makanan tersebut pada gambar.

      Untuk SETIAP item makanan yang valid, tentukan:
      1. "keyword": Nama makanan bersih tanpa atribut jumlah dalam format Title Case (Cth: "Sate Ayam").
      2. "quantity": Angka estimasi porsi/jumlahnya pada objek gambar (Cth: 3.0).
      3. "fallback_cal": Total Estimasi kalori referensi valid per 1 porsi standar (angka).
      4. "fallback_p": Total Estimasi protein referensi valid per 1 porsi standar (g).
      5. "fallback_c": Total Estimasi karbohidrat referensi valid per 1 porsi standar (g).
      6. "fallback_f": Total Estimasi lemak referensi valid per 1 porsi standar (g).
      7. "box_2d": Array 4 angka [ymin, xmin, ymax, xmax] yang mewakili kotak deteksi dengan skala 0-1000. Jika tidak ada gambar, kembalikan [0,0,0,0].

      Kembalikan HANYA format JSON Array ketat tanpa awalan markdown.
      ''';

      final response = await _supabase.functions.invoke(
        'analyze_food',
        body: {
          'prompt': prompt,
          'base64Image': base64Image,
        },
      );

      if (response.status == 200) {
        final aiResponseData = response.data;

        final aiTextResponse = aiResponseData['candidates'][0]['content']['parts'][0]['text'];

        String cleanText = (aiTextResponse ?? '[]').replaceAll('```json', '').replaceAll('```', '').trim();

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

      } else {
        final errorMsg = response.data['error'] ?? 'Unknown Server Error';
        if (errorMsg.contains('Limit Exceeded')) {
          throw Exception(tr('all_ai_tokens_exhausted'));
        }
        throw Exception('${tr('failed_process_ai')} $errorMsg');
      }

    } catch (e) {
      if (e.toString().contains('all_ai_tokens_exhausted')) {
        rethrow;
      }
      throw Exception('${tr('unexpected_ai_error')} $e');
    }
  }
}