import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import '../../data/models/presales_query_model.dart';
import '../../data/models/product_model.dart';
import 'package:uuid/uuid.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Run this daily at 9:00 AM
  Future<void> checkDailyReminders() async {
    print('DEBUG: checkDailyReminders() START');
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    
    print('DEBUG: Today is $now');
    print('DEBUG: Checking for follow-ups between $tomorrowStart and ${tomorrowStart.add(const Duration(days: 1))}');

    // 1. Check Pre-Sales Follow-ups due Tomorrow
    try {
      final presalesSnapshot = await _firestore
          .collection(FirestoreCollections.preSalesQueries)
          .where('followUpScheduledDate', isGreaterThanOrEqualTo: tomorrowStart)
          .where('followUpScheduledDate', isLessThan: tomorrowStart.add(const Duration(days: 1)))
          .get();
      
      print('DEBUG: Found ${presalesSnapshot.docs.length} presales queries due for follow-up tomorrow.');

      for (var doc in presalesSnapshot.docs) {
        print('DEBUG: Processing follow-up for doc ${doc.id}');
        await _logReminder(
          linkedId: doc.id,
          employeeName: 'Assigned Sales Rep', 
          type: 'Proactive Follow-up',
        );
        // Set flag
        await doc.reference.update({'followUpReminderTomorrow': true});
      }
    } catch (e) {
      print('DEBUG ERROR (Follow-ups): $e');
    }

    // 2. Check Pre-Sales SLA (Reply Commitment) Due Today
    try {
      final slaSnapshot = await _firestore.collection(FirestoreCollections.preSalesQueries)
          .where('proposalStatus', isEqualTo: 'proposal_sent')
          .get();
      
      print('DEBUG: Found ${slaSnapshot.docs.length} sent proposals to check for SLA.');
          
      for (var doc in slaSnapshot.docs) {
         final query = PreSalesQuery.fromSnapshot(doc);
         if (query.proposalSentDate != null) {
            final deadline = query.proposalSentDate!.add(Duration(days: query.replyCommitmentDays));
            print('DEBUG: Query ${query.id} sent on ${query.proposalSentDate}, deadline: $deadline');
            
            if (deadline.year == now.year && deadline.month == now.month && deadline.day == now.day) {
              print('DEBUG: SLA Deadline HIT for ${query.id}');
              await _logReminder(
                linkedId: query.id,
                employeeName: query.latestUpdatedBy ?? 'Sales Team',
                type: 'Pre-Sales Reply Deadline Today',
              );
            }
         }
      }
    } catch (e) {
      print('DEBUG ERROR (SLA Check): $e');
    }

    // 3. Check Pre-Sales Internal Approvals Done Today
    try {
      final approvedSnapshot = await _firestore.collection(FirestoreCollections.preSalesQueries)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();
      
      print('DEBUG: Found ${approvedSnapshot.docs.length} approved queries.');

      for (var doc in approvedSnapshot.docs) {
         final query = PreSalesQuery.fromSnapshot(doc);
         if (query.proposalApprovalDate != null) {
            if (query.proposalApprovalDate!.year == now.year && 
                query.proposalApprovalDate!.month == now.month && 
                query.proposalApprovalDate!.day == now.day) {
               print('DEBUG: Approval reminder HIT for ${query.id}');
               await _logReminder(
                linkedId: query.id,
                employeeName: query.proposalApprovedBy ?? 'Manager',
                type: 'Internal Approval Done - Send Proposal',
              );
            }
         }
      }
    } catch (e) {
      print('DEBUG ERROR (Approvals): $e');
    }

    // 4. Check Service Ticket SLA Breaches due Today
    try {
      final ticketSnapshot = await _firestore.collection(FirestoreCollections.serviceTickets)
          .where('status', whereIn: ['open', 'in_progress']).get();
      
      print('DEBUG: Found ${ticketSnapshot.docs.length} active service tickets.');

      for (var doc in ticketSnapshot.docs) {
        final ticket = ServiceTicket.fromSnapshot(doc);
        if (ticket.serviceSLAReplyDays > 0) {
          final deadline = ticket.issueReceivedDate.add(Duration(days: ticket.serviceSLAReplyDays));
          if (deadline.year == now.year && deadline.month == now.month && deadline.day == now.day) {
            print('DEBUG: Service Ticket SLA HIT for ${ticket.id}');
            await _logReminder(
              linkedId: ticket.id,
              employeeName: ticket.assignedEmployeeName.isNotEmpty ? ticket.assignedEmployeeName : 'Service Admin',
              type: 'Service SLA Deadline Today',
            );
          }
        }
        
        // 5. Check Unassigned Tickets (Proposal Accepted)
        if (ticket.proposalStatus == 'accepted' && ticket.assignedEmployeeId.isEmpty) {
           print('DEBUG: Unassigned Ticket HIT for ${ticket.id}');
           await _logReminder(
              linkedId: ticket.id,
              employeeName: 'Service Manager',
              type: 'Urgent: Assign Engineer (Proposal Accepted)',
           );
        }
      }
    } catch (e) {
       print('DEBUG ERROR (Service Tickets): $e');
    }

    // 6. Check Warranty Expiry (7 Days & 30 Days)
    try {
      // Checking all products is expensive. Ideally, query by range.
      // final sevenDaysLater = now.add(const Duration(days: 7));
      // final thirtyDaysLater = now.add(const Duration(days: 30));
      
      // We can do a range query if we have 'warrantyEndDate' indexed.
      // simpler to query start/end of the specific target dates.
      
      final wSnapshot = await _firestore.collection(FirestoreCollections.products)
        .where('warrantyEndDate', isGreaterThan: now) // Only active
        .get(); 
      
      print('DEBUG: Checking warranty expiry for ${wSnapshot.docs.length} active products.');

      for (var doc in wSnapshot.docs) {
         final p = ProductModel.fromSnapshot(doc);
         final daysRef = p.warrantyEndDate.difference(now).inDays;
         
         if (daysRef == 7 || daysRef == 30) {
            print('DEBUG: Warranty Expiry HIT ($daysRef days) for ${p.id}');
            await _logReminder(
              linkedId: p.id,
              employeeName: 'Sales/Service Team',
              type: 'Warranty Expiring in $daysRef Days',
            );
         }
      }
    } catch (e) {
      print('DEBUG ERROR (Warranty): $e');
    }
    
    print('DEBUG: checkDailyReminders() END');
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
