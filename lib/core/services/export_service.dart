import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {

  // Menerima data gabungan: 0 = 7 Days, 1 = 4 Weeks, 2 = 6 Months
  Future<void> exportToPdf(Map<int, Map<String, dynamic>> allData) async {
    final pdf = pw.Document();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Menggunakan MultiPage agar bisa membuat halaman baru otomatis jika tabel terlalu panjang
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> widgets = [
            pw.Text('CalTrack Progress Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Generated on: $today'),
            pw.SizedBox(height: 20),
          ];

          final titles = ['Last 7 Days', 'Last 4 Weeks', 'Last 6 Months'];

          // Looping untuk membuat 3 tabel
          for (int i = 0; i < 3; i++) {
            if (allData[i] == null) continue;

            final data = allData[i]!;
            final List<double> workout = data['workout'] ?? [];
            final List<double> burned = data['burned'] ?? [];
            final List<double> consumed = data['consumed'] ?? [];
            final List<double> water = data['water'] ?? [];
            // Mengambil tanggal lengkap yang kita siapkan di screen
            final List<String> labels = List<String>.from(data['exportDates']);

            widgets.add(pw.Text(titles[i], style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)));
            widgets.add(pw.SizedBox(height: 10));

            widgets.add(
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Date / Period', 'Calories In (kcal)', 'Calories Out (kcal)', 'Water (ml)', 'Workout (min)'],
                  data: List.generate(labels.length, (index) {
                    return [
                      labels[index],
                      consumed[index].round().toString(),
                      burned[index].round().toString(),
                      water[index].round().toString(),
                      workout[index].round().toString(),
                    ];
                  }),
                  border: pw.TableBorder.all(width: 1, color: PdfColors.grey400),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  cellAlignment: pw.Alignment.center,
                )
            );

            widgets.add(pw.SizedBox(height: 24)); // Spasi antar tabel
          }

          return widgets;
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/CalTrack_Report_$today.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'CalTrack Progress Report - $today');
  }

  Future<void> exportToCsv(Map<int, Map<String, dynamic>> allData) async {
    List<List<dynamic>> rows = [];
    final titles = ['--- LAST 7 DAYS ---', '--- LAST 4 WEEKS ---', '--- LAST 6 MONTHS ---'];

    for (int i = 0; i < 3; i++) {
      if (allData[i] == null) continue;

      final data = allData[i]!;
      final List<double> workout = data['workout'] ?? [];
      final List<double> burned = data['burned'] ?? [];
      final List<double> consumed = data['consumed'] ?? [];
      final List<double> water = data['water'] ?? [];
      final List<String> labels = List<String>.from(data['exportDates']);

      // Menambahkan Judul Bagian
      rows.add([titles[i]]);
      // Menambahkan Header Kolom
      rows.add(['Date / Period', 'Calories In (kcal)', 'Calories Out (kcal)', 'Water (ml)', 'Workout (min)']);

      // Menambahkan Isi
      for (int j = 0; j < labels.length; j++) {
        rows.add([
          labels[j],
          consumed[j].round(),
          burned[j].round(),
          water[j].round(),
          workout[j].round(),
        ]);
      }

      rows.add([]);
    }

    String csvData = rows.map((row) => row.join(',')).join('\n');

    final dir = await getTemporaryDirectory();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/CalTrack_Report_$today.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'CalTrack Progress Report - $today');
  }
}