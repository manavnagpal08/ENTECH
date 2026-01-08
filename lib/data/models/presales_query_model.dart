import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String text;
  final String addedBy;
  final DateTime date;

  Note({required this.text, required this.addedBy, required this.date});

  Map<String, dynamic> toMap() => {
        'text': text,
        'addedBy': addedBy,
        'date': date.toIso8601String(),
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        text: map['text'] ?? '',
        addedBy: map['addedBy'] ?? '',
        date: DateTime.parse(map['date']),
      );
}

class PreSalesQuery {
  final String id;
  final String querySource;
  final String customerName;
  final String phoneNumber;
  final String email;
  final String? companyName;
  final Map<String, dynamic> location;
  final String productQueryDescription;
  final DateTime queryReceivedDate;
  final DateTime? proposalSentDate;
  final DateTime? proposalAcceptedDate;
  final DateTime? proposalRejectedDate;
  final String proposalStatus;
  final int replyCommitmentDays;
  final String approvalStatus;
  final DateTime? proposalApprovalDate;
  final String? proposalApprovedBy;
  final String? proposalApprovalNotes;
  final DateTime? followUpScheduledDate;
  final bool followUpReminderTomorrow;
  final List<Note> notesThread;
  final DateTime? latestUpdateOn;
  final String? latestUpdatedBy;

  PreSalesQuery({
    required this.id,
    required this.querySource,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    this.companyName,
    this.location = const {},
    required this.productQueryDescription,
    required this.queryReceivedDate,
    this.proposalSentDate,
    this.proposalAcceptedDate,
    this.proposalRejectedDate,
    this.proposalStatus = 'new',
    this.replyCommitmentDays = 2,
    this.approvalStatus = 'pending',
    this.proposalApprovalDate,
    this.proposalApprovedBy,
    this.proposalApprovalNotes,
    this.followUpScheduledDate,
    this.followUpReminderTomorrow = false,
    this.notesThread = const [],
    this.latestUpdateOn,
    this.latestUpdatedBy,
  });

  // Auto-computed message
  String get replyCommitmentMessage => "We will reply to your proposal in $replyCommitmentDays days.";

  Map<String, dynamic> toMap() {
    return {
      'querySource': querySource,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'companyName': companyName,
      'location': location,
      'productQueryDescription': productQueryDescription,
      'queryReceivedDate': Timestamp.fromDate(queryReceivedDate),
      'proposalSentDate': proposalSentDate != null ? Timestamp.fromDate(proposalSentDate!) : null,
      'proposalAcceptedDate': proposalAcceptedDate != null ? Timestamp.fromDate(proposalAcceptedDate!) : null,
      'proposalRejectedDate': proposalRejectedDate != null ? Timestamp.fromDate(proposalRejectedDate!) : null,
      'proposalStatus': proposalStatus,
      'replyCommitmentDays': replyCommitmentDays,
      'approvalStatus': approvalStatus,
      'proposalApprovalDate': proposalApprovalDate != null ? Timestamp.fromDate(proposalApprovalDate!) : null,
      'proposalApprovedBy': proposalApprovedBy,
      'proposalApprovalNotes': proposalApprovalNotes,
      'followUpScheduledDate': followUpScheduledDate != null ? Timestamp.fromDate(followUpScheduledDate!) : null,
      'followUpReminderTomorrow': followUpReminderTomorrow,
      'notesThread': notesThread.map((n) => n.toMap()).toList(),
      'latestUpdateOn': latestUpdateOn != null ? Timestamp.fromDate(latestUpdateOn!) : FieldValue.serverTimestamp(),
      'latestUpdatedBy': latestUpdatedBy,
    };
  }

  factory PreSalesQuery.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PreSalesQuery(
      id: doc.id,
      querySource: data['querySource'] ?? '',
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      companyName: data['companyName'],
      location: data['location'] ?? {},
      productQueryDescription: data['productQueryDescription'] ?? '',
      queryReceivedDate: (data['queryReceivedDate'] as Timestamp).toDate(),
      proposalSentDate: (data['proposalSentDate'] as Timestamp?)?.toDate(),
      proposalAcceptedDate: (data['proposalAcceptedDate'] as Timestamp?)?.toDate(),
      proposalRejectedDate: (data['proposalRejectedDate'] as Timestamp?)?.toDate(),
      proposalStatus: data['proposalStatus'] ?? 'new',
      replyCommitmentDays: data['replyCommitmentDays'] ?? 2,
      approvalStatus: data['approvalStatus'] ?? 'pending',
      proposalApprovalDate: (data['proposalApprovalDate'] as Timestamp?)?.toDate(),
      proposalApprovedBy: data['proposalApprovedBy'],
      proposalApprovalNotes: data['proposalApprovalNotes'],
      followUpScheduledDate: (data['followUpScheduledDate'] as Timestamp?)?.toDate(),
      followUpReminderTomorrow: data['followUpReminderTomorrow'] ?? false,
      notesThread: (data['notesThread'] as List<dynamic>?)
              ?.map((e) => Note.fromMap(e))
              .toList() ??
          [],
      latestUpdateOn: (data['latestUpdateOn'] as Timestamp?)?.toDate(),
      latestUpdatedBy: data['latestUpdatedBy'],
    );
  }
}
