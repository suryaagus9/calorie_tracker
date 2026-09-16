import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<void> exportToPdf(Map<String, dynamic> rawData, List<String> labels) async {
    final pdf = pw.Document();

    final List<double> workout = rawData['workout'] ?? [];
    final List<double> burned = rawData['burned'] ?? [];
    final List<double> consumed = rawData['consumed'] ?? [];
    final List<double> water = rawData['water'] ?? [];

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CalTrack Progress Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Generated on: $today'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Label', 'Calories In (kcal)', 'Calories Out (kcal)', 'Water (ml)', 'Workout (min)'],
                data: List.generate(labels.length, (index) {
                  return [
                    labels[index],
                    consumed[index].round().toString(),
                    burned[index].round().toString(),
                    water[index].round().toString(),
                    workout[index].round().toString(),
                  ];
                }),
                border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.center,
              ),
            ],
          );
        },
      ),
    );

    // Menyimpan secara lokal di memori sementara
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/CalTrack_Report_$today.pdf');
    await file.writeAsBytes(await pdf.save());

    // Membuka menu sistem bawaan HP (Bisa di-Share atau di-Save)
    await Share.shareXFiles([XFile(file.path)], text: 'CalTrack Progress Report - $today');
  }

  Future<void> exportToCsv(Map<String, dynamic> rawData, List<String> labels) async {
    final List<double> workout = rawData['workout'] ?? [];
    final List<double> burned = rawData['burned'] ?? [];
    final List<double> consumed = rawData['consumed'] ?? [];
    final List<double> water = rawData['water'] ?? [];

    List<List<dynamic>> rows = [];
    // Header
    rows.add(['Label', 'Calories In (kcal)', 'Calories Out (kcal)', 'Water (ml)', 'Workout (min)']);

    // Isi Data
    for (int i = 0; i < labels.length; i++) {
      rows.add([
        labels[i],
        consumed[i].round(),
        burned[i].round(),
        water[i].round(),
        workout[i].round(),
      ]);
    }

    // Merakit file CSV
    String csvData = rows.map((row) => row.join(',')).join('\n');

    // Menyimpan secara lokal di memori sementara
    final dir = await getTemporaryDirectory();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${dir.path}/CalTrack_Report_$today.csv');
    await file.writeAsString(csvData);

    // Membuka menu sistem bawaan HP (Bisa di-Share atau di-Save)
    await Share.shareXFiles([XFile(file.path)], text: 'CalTrack Progress Report - $today');
  }
}