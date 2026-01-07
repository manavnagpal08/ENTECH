import '../data/models/product_model.dart';
import '../data/models/presales_query_model.dart';

class WarrantyEngine {
  static String calculateStatus(DateTime endDate) {
    final now = DateTime.now();
    // Normalize to date only
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    
    if (today.isBefore(end) || today.isAtSameMomentAs(end)) {
      return 'in_warranty';
    } else {
      return 'out_of_warranty';
    }
  }

  static String determineChargeType(String warrantyStatus, String manualOverride) {
    if (manualOverride.isNotEmpty) return manualOverride;
    if (warrantyStatus == 'in_warranty') return 'free';
    return 'paid';
  }
}

class NotesMerger {
  /// Merges notes from various sources into a single readable paragraph
  static String generateSummary({
    required List<Note> threadNotes,
    String? saleNotes,
    String? serviceNotes,
    String? approvalNotes,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('--- MERGED NOTES SUMMARY ---');
    
    if (saleNotes != null && saleNotes.isNotEmpty) {
       buffer.writeln('[Sale]: $saleNotes');
    }

    if (threadNotes.isNotEmpty) {
      buffer.writeln('\n[History]:');
      for (final note in threadNotes) {
        buffer.writeln('- ${note.date.toString().split(' ')[0]} (${note.addedBy}): ${note.text}');
      }
    }

    if (approvalNotes != null && approvalNotes.isNotEmpty) {
      buffer.writeln('\n[Approval]: $approvalNotes');
    }

    if (serviceNotes != null && serviceNotes.isNotEmpty) {
       buffer.writeln('\n[Service]: $serviceNotes');
    }

    return buffer.toString().trim();
  }
}
