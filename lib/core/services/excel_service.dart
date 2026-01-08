// import 'dart:io'; // REMOVED FOR WEB COMPATIBILITY
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/presales_query_model.dart';
// import 'dart:typed_data';

class ExcelService {
  final _uuid = const Uuid();

  Future<List<PreSalesQuery>> parsePreSalesExcel(List<int> bytes) async {
    try {
      // final bytes = File(filePath).readAsBytesSync(); // REMOVED
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

          // Col 5: Enquiry No & Date (e.g., "101 / 20-04-2025")
          final enquiryRaw = row.length > 5 ? _getCellValue(row[5]) : '';
          final queryDate = _parseDateFromText(enquiryRaw) ?? DateTime.now();

          // Col 6: Quotation Date (Proposal Sent)
          final quoteRaw = row.length > 6 ? _getCellValue(row[6]) : '';
          final sentDate = _parseDateFromText(quoteRaw);

          // Logic for Status based on dates
          String status = 'new';
          if (sentDate != null) status = 'proposal_sent';
          
          // Check for "Accepted" in status column if it exists (assuming Col 10 or inferred)
          // For now, if user said "Proposal Accepted column", let's assume it might be Col 10
          final acceptedRaw = row.length > 10 ? _getCellValue(row[10]) : '';
          final acceptedDate = _parseDateFromText(acceptedRaw);
          if (acceptedDate != null) status = 'accepted';

          // Extract basic info
          final partyName = _getCellValue(row[2]);
          if (partyName.isEmpty) continue;

          final contactInfo = _getCellValue(row[4]);
          
          queries.add(PreSalesQuery(
            id: _uuid.v4(),
            querySource: 'Excel Import',
            customerName: partyName,
            phoneNumber: _extractPhone(contactInfo),
            email: _extractEmail(contactInfo),
            location: {
              'address': _getCellValue(row[3]),
              'city': row.length > 8 ? _getCellValue(row[8]) : '',
              'state': row.length > 9 ? _getCellValue(row[9]) : '',
            },
            productQueryDescription: row.length > 7 ? _getCellValue(row[7]) : 'Imported Inquiry',
            queryReceivedDate: queryDate,
            proposalSentDate: sentDate,
            proposalAcceptedDate: acceptedDate,
            proposalStatus: status,
            notesThread: [
              Note(
                text: 'Imported from Excel. Original Row: ${row[0]?.value}. Enq: $enquiryRaw',
                addedBy: 'System (Import)',
                date: DateTime.now(),
              )
            ],
            latestUpdateOn: DateTime.now(),
            latestUpdatedBy: 'System',
          ));
        }
      }
      return queries;
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing excel: $e');
      rethrow;
    }
  }

  DateTime? _parseDateFromText(String text) {
    if (text.isEmpty) return null;
    // Regex for dd-MM-yyyy or dd/MM/yyyy
    final regex = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})');
    final match = regex.firstMatch(text);
    if (match != null) {
      try {
        int d = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        int y = int.parse(match.group(3)!);
        if (y < 100) y += 2000; // Handle yy
        return DateTime(y, m, d);
      } catch (e) {
        return null;
      }
    }
    return null;
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
