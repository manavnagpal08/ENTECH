import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeAction {
  final String employeeName;
  final String action;
  final DateTime date;
  final String? notes;

  EmployeeAction({required this.employeeName, required this.action, required this.date, this.notes});

  Map<String, dynamic> toMap() => {
    'employeeName': employeeName,
    'action': action,
    'date': Timestamp.fromDate(date),
    'notes': notes,
  };

  factory EmployeeAction.fromMap(Map<String, dynamic> map) => EmployeeAction(
    employeeName: map['employeeName'] ?? '',
    action: map['action'] ?? '',
    date: (map['date'] as Timestamp).toDate(),
    notes: map['notes'],
  );
}

class UsedPart {
  final String partName;
  final int qty;
  final DateTime replacedOn;

  UsedPart({required this.partName, required this.qty, required this.replacedOn});

  Map<String, dynamic> toMap() => {
    'partName': partName,
    'qty': qty,
    'replacedOn': Timestamp.fromDate(replacedOn),
  };

  factory UsedPart.fromMap(Map<String, dynamic> map) => UsedPart(
    partName: map['partName'] ?? '',
    qty: map['qty'] ?? 1,
    replacedOn: (map['replacedOn'] as Timestamp).toDate(),
  );
}

class ServiceTicket {
  final String id;
  final String linkedSerialNumber;
  final String issueDescription;
  final DateTime issueReceivedDate;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String assignedEmployeeId;
  final String assignedEmployeeName;
  final int serviceSLAReplyDays;
  final bool followUpReminderTomorrow;
  
  // Warranty & Cost
  final String warrantyStatus; // 'in_warranty', 'out_of_warranty'
  final String serviceChargeType; // 'free', 'paid'
  
  // Proposal & Quotes
  final DateTime? proposalSentDate;
  final DateTime? proposalAcceptedDate;
  final DateTime? proposalRejectedDate;
  final String proposalStatus; // 'pending', 'sent', 'accepted', 'rejected'

  // History & Actions
  final List<EmployeeAction> actions;
  final List<UsedPart> usedParts;
  final String? finalServiceSummary;
  final String? mergedNotesSummary;

  // Feedback
  final int? rating;
  final String? feedbackText;

  ServiceTicket({
    required this.id,
    required this.linkedSerialNumber,
    required this.issueDescription,
    required this.issueReceivedDate,
    required this.status,
    required this.assignedEmployeeId,
    required this.assignedEmployeeName,
    this.serviceSLAReplyDays = 2,
    this.followUpReminderTomorrow = false,
    this.warrantyStatus = 'unknown',
    this.serviceChargeType = 'paid',
    this.proposalSentDate,
    this.proposalAcceptedDate,
    this.proposalRejectedDate,
    this.proposalStatus = 'pending',
    required this.actions,
    required this.usedParts,
    this.finalServiceSummary,
    this.mergedNotesSummary,
    this.rating,
    this.feedbackText,
  });

  bool get isSLABreached {
    if (status == 'closed') return false;
    final deadline = issueReceivedDate.add(Duration(days: serviceSLAReplyDays));
    return DateTime.now().isAfter(deadline);
  }

  Map<String, dynamic> toMap() {
    return {
      'linkedSerialNumber': linkedSerialNumber,
      'issueDescription': issueDescription,
      'issueReceivedDate': Timestamp.fromDate(issueReceivedDate),
      'status': status,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'serviceSLAReplyDays': serviceSLAReplyDays,
      'followUpReminderTomorrow': followUpReminderTomorrow,
      'warrantyStatus': warrantyStatus,
      'serviceChargeType': serviceChargeType,
      'proposalSentDate': proposalSentDate != null ? Timestamp.fromDate(proposalSentDate!) : null,
      'proposalAcceptedDate': proposalAcceptedDate != null ? Timestamp.fromDate(proposalAcceptedDate!) : null,
      'proposalRejectedDate': proposalRejectedDate != null ? Timestamp.fromDate(proposalRejectedDate!) : null,
      'proposalStatus': proposalStatus,
      'actions': actions.map((e) => e.toMap()).toList(),
      'usedParts': usedParts.map((e) => e.toMap()).toList(),
      'finalServiceSummary': finalServiceSummary,
      'mergedNotesSummary': mergedNotesSummary,
      'rating': rating,
      'feedbackText': feedbackText,
    };
  }

  factory ServiceTicket.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceTicket(
      id: doc.id,
      linkedSerialNumber: data['linkedSerialNumber'] ?? '',
      issueDescription: data['issueDescription'] ?? '',
      issueReceivedDate: (data['issueReceivedDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'open',
      assignedEmployeeId: data['assignedEmployeeId'] ?? '',
      assignedEmployeeName: data['assignedEmployeeName'] ?? '',
      serviceSLAReplyDays: data['serviceSLAReplyDays'] ?? 2,
      followUpReminderTomorrow: data['followUpReminderTomorrow'] ?? false,
      warrantyStatus: data['warrantyStatus'] ?? 'unknown',
      serviceChargeType: data['serviceChargeType'] ?? 'paid',
      proposalSentDate: (data['proposalSentDate'] as Timestamp?)?.toDate(),
      proposalAcceptedDate: (data['proposalAcceptedDate'] as Timestamp?)?.toDate(),
      proposalRejectedDate: (data['proposalRejectedDate'] as Timestamp?)?.toDate(),
      proposalStatus: data['proposalStatus'] ?? 'pending',
      actions: (data['actions'] as List<dynamic>?)
              ?.map((e) => EmployeeAction.fromMap(e))
              .toList() ??
          [],
      usedParts: (data['usedParts'] as List<dynamic>?)
              ?.map((e) => UsedPart.fromMap(e))
              .toList() ??
          [],
      finalServiceSummary: data['finalServiceSummary'],
      mergedNotesSummary: data['mergedNotesSummary'],
      rating: data['rating'],
      feedbackText: data['feedbackText'],
    );
  }
}
