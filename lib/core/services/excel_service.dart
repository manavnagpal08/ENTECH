import 'dart:io';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../data/models/presales_query_model.dart';

class ExcelService {
  final _uuid = const Uuid();

  Future<List<PreSalesQuery>> parsePreSalesExcel(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final List<PreSalesQuery> queries = [];

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Assuming Row 0 is header, start from 1
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          if (row.isEmpty) continue;

          // Mapping based on user's excel sample:
          // Col 0: S.No, 1: Q.No, 2: Party Name, 3: Address, 4: Ph/Email
          // 5: Enquiry No & Date, 6: Quotation Date, 7: Items, 8: City, 9: State
          
          if (row.length < 5) continue; // Skip malformed rows

          final partyName = _getCellValue(row[2]);
          if (partyName.isEmpty) continue;

          final contactInfo = _getCellValue(row[4]);
          final phone = _extractPhone(contactInfo);
          final email = _extractEmail(contactInfo);
          
          final address = _getCellValue(row[3]);
          final city = row.length > 8 ? _getCellValue(row[8]) : '';
          final state = row.length > 9 ? _getCellValue(row[9]) : '';

          queries.add(PreSalesQuery(
            id: _uuid.v4(),
            querySource: 'Excel Import',
            customerName: partyName,
            phoneNumber: phone,
            email: email,
            location: {
              'address': address,
              'city': city,
              'state': state,
            },
            productQueryDescription: row.length > 7 ? _getCellValue(row[7]) : 'Imported Inquiry',
            queryReceivedDate: DateTime.now(), // Default as we might not parse complex date strings perfectly
            notesThread: [
              Note(
                text: 'Imported from Excel. Original Row: ${row[0]?.value}',
                addedBy: 'System',
                date: DateTime.now(),
              )
            ],
          ));
        }
      }
      return queries;
    } catch (e) {
      print('Error parsing excel: $e');
      rethrow;
    }
  }

  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  String _extractPhone(String text) {
    final regex = RegExp(r'(\d{10,})');
    final match = regex.firstMatch(text);
    return match?.group(0) ?? '';
  }

  String _extractEmail(String text) {
    final regex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final match = regex.firstMatch(text);
    return match?.group(0) ?? '';
  }
}
