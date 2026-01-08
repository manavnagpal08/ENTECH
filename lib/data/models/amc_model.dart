import 'package:cloud_firestore/cloud_firestore.dart';

class AmcContract {
  final String id;
  final String linkedSerialNumber;
  final String linkedProductName;
  final String customerName;
  final String phoneNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int totalVisits;
  final int visitsCompleted;
  final double contractAmount;
  final String status; // 'active', 'expired', 'renewed'
  final List<DateTime> visitDates;

  AmcContract({
    required this.id,
    required this.linkedSerialNumber,
    required this.linkedProductName,
    required this.customerName,
    required this.phoneNumber,
    required this.startDate,
    required this.endDate,
    required this.totalVisits,
    this.visitsCompleted = 0,
    required this.contractAmount,
    this.status = 'active',
    this.visitDates = const [],
  });

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toMap() {
    return {
      'linkedSerialNumber': linkedSerialNumber,
      'linkedProductName': linkedProductName,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalVisits': totalVisits,
      'visitsCompleted': visitsCompleted,
      'contractAmount': contractAmount,
      'status': status,
      'visitDates': visitDates.map((d) => Timestamp.fromDate(d)).toList(),
    };
  }

  factory AmcContract.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AmcContract(
      id: doc.id,
      linkedSerialNumber: data['linkedSerialNumber'] ?? '',
      linkedProductName: data['linkedProductName'] ?? '',
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalVisits: data['totalVisits'] ?? 4,
      visitsCompleted: data['visitsCompleted'] ?? 0,
      contractAmount: (data['contractAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
      visitDates: (data['visitDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
    );
  }
}
