import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import 'package:uuid/uuid.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Run this daily at 9:00 AM
  Future<void> checkDailyReminders() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // 1. Check Pre-Sales Follow-ups due Tomorrow
    final presalesSnapshot = await _firestore
        .collection(FirestoreCollections.preSalesQueries)
        .where('followUpScheduledDate', isGreaterThanOrEqualTo: tomorrowStart)
        .where('followUpScheduledDate', isLessThan: tomorrowStart.add(const Duration(days: 1)))
        .get();

    for (var doc in presalesSnapshot.docs) {
      await _logReminder(
        linkedId: doc.id,
        employeeName: 'Assigned Sales Rep', // In real app, fetch from doc
        type: 'Proactive Follow-up',
      );
      // Set flag
      await doc.reference.update({'followUpReminderTomorrow': true});
    }

    // 2. Check SLA Breaches due Today
    final ticketSnapshot = await _firestore.collection(FirestoreCollections.serviceTickets)
        .where('status', whereIn: ['open', 'in_progress']).get();

    for (var doc in ticketSnapshot.docs) {
      final ticket = ServiceTicket.fromSnapshot(doc);
      final deadline = ticket.issueReceivedDate.add(Duration(days: ticket.serviceSLAReplyDays));
      
      if (deadline.year == now.year && deadline.month == now.month && deadline.day == now.day) {
        await _logReminder(
          linkedId: ticket.id,
          employeeName: ticket.assignedEmployeeName,
          type: 'SLA Deadline Today',
        );
      }
    }
  }

  // Run this daily at 4:30 PM
  Future<void> checkEscalations() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Find reminders created today that are still pending
    final logsSnapshot = await _firestore.collection(FirestoreCollections.reminderLogs)
        .where('reminderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('completionStatus', isEqualTo: 'pending')
        .where('escalationStatus', isEqualTo: 'none')
        .get();

    for (var doc in logsSnapshot.docs) {
      await doc.reference.update({
        'escalationStatus': 'escalated',
        'escalatedOn': FieldValue.serverTimestamp(),
        'escalationNotes': 'Auto-escalated: Task not completed by 4:00 PM',
      });
    }
  }

  Future<void> _logReminder({
    required String linkedId,
    required String employeeName,
    required String type,
  }) async {
    final id = _uuid.v4();
    await _firestore.collection(FirestoreCollections.reminderLogs).doc(id).set({
      'logId': id,
      'linkedId': linkedId,
      'employeeName': employeeName,
      'reminderType': type,
      'reminderDate': FieldValue.serverTimestamp(),
      'completionStatus': 'pending',
      'escalationStatus': 'none',
      'escalationNotes': '',
    });
  }

  Future<void> markReminderDone(String linkedId) async {
    // Find active reminder for this link
    final snapshot = await _firestore.collection(FirestoreCollections.reminderLogs)
        .where('linkedId', isEqualTo: linkedId)
        .where('completionStatus', isEqualTo: 'pending')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'completionStatus': 'done',
        'completedOn': FieldValue.serverTimestamp(),
      });
    }
    
    // Reset flags on the actual document if needed
    // e.g. await _firestore.collection(...).doc(linkedId).update({'followUpReminderTomorrow': false});
  }
}
