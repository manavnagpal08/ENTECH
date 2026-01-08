import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceHistoryItem {
  final String ticketId;
  final String issueDescription;
  final DateTime resolvedOn;
  final String partsReplacedSummary;
  final String notesSummary;
  final String warrantyStatusAtService; // 'in_warranty' or 'out_of_warranty'

  ServiceHistoryItem({
    required this.ticketId,
    required this.issueDescription,
    required this.resolvedOn,
    required this.partsReplacedSummary,
    required this.notesSummary,
    required this.warrantyStatusAtService,
  });

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'issueDescription': issueDescription,
        'resolvedOn': Timestamp.fromDate(resolvedOn),
        'partsReplacedSummary': partsReplacedSummary,
        'notesSummary': notesSummary,
        'warrantyStatusAtService': warrantyStatusAtService,
      };

  factory ServiceHistoryItem.fromMap(Map<String, dynamic> map) {
    return ServiceHistoryItem(
      ticketId: map['ticketId'] ?? '',
      issueDescription: map['issueDescription'] ?? '',
      resolvedOn: (map['resolvedOn'] as Timestamp).toDate(),
      partsReplacedSummary: map['partsReplacedSummary'] ?? '',
      notesSummary: map['notesSummary'] ?? '',
      warrantyStatusAtService: map['warrantyStatusAtService'] ?? 'unknown',
    );
  }
}

class ProductModel {
  final String id; // productId
  final String serialNumber;
  final String productName;
  final String modelOrVariant;
  final String customerName;
  final String phoneNumber;
  final String email;
  final DateTime purchaseDate;
  final String warrantyType;
  final int warrantyDurationMonths;
  final DateTime warrantyStartDate;
  final DateTime warrantyEndDate;
  final int warrantyClaimCount;
  final int warrantyRejectedCount;
  final DateTime? lastClaimDate;
  final DateTime? lastWarrantyCheck;
  final List<ServiceHistoryItem> serviceHistory;
  final String? serviceCertificateURL;
  final Map<String, dynamic> location;
  final String notes;
  final DateTime? latestUpdatedOn;
  final String? latestUpdatedBy;

  ProductModel({
    required this.id,
    required this.serialNumber,
    required this.productName,
    required this.modelOrVariant,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    required this.purchaseDate,
    this.warrantyType = 'standard',
    this.warrantyDurationMonths = 12,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
    this.warrantyClaimCount = 0,
    this.warrantyRejectedCount = 0,
    this.lastClaimDate,
    this.lastWarrantyCheck,
    this.serviceHistory = const [],
    this.serviceCertificateURL,
    this.location = const {},
    this.notes = '',
    this.latestUpdatedOn,
    this.latestUpdatedBy,
  });

  bool get isWarrantyValid => DateTime.now().isBefore(warrantyEndDate);

  Map<String, dynamic> toMap() {
    return {
      'serialNumber': serialNumber,
      'productName': productName,
      'modelOrVariant': modelOrVariant,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'warrantyType': warrantyType,
      'warrantyDurationMonths': warrantyDurationMonths,
      'warrantyStartDate': Timestamp.fromDate(warrantyStartDate),
      'warrantyEndDate': Timestamp.fromDate(warrantyEndDate),
      'warrantyClaimCount': warrantyClaimCount,
      'warrantyRejectedCount': warrantyRejectedCount,
      'lastClaimDate': lastClaimDate != null ? Timestamp.fromDate(lastClaimDate!) : null,
      'lastWarrantyCheck': lastWarrantyCheck != null ? Timestamp.fromDate(lastWarrantyCheck!) : null,
      'serviceHistory': serviceHistory.map((e) => e.toMap()).toList(),
      'serviceCertificateURL': serviceCertificateURL,
      'location': location,
      'notes': notes,
      'latestUpdatedOn': latestUpdatedOn != null ? Timestamp.fromDate(latestUpdatedOn!) : FieldValue.serverTimestamp(),
      'latestUpdatedBy': latestUpdatedBy,
    };
  }

  factory ProductModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      serialNumber: data['serialNumber'] ?? '',
      productName: data['productName'] ?? '',
      modelOrVariant: data['modelOrVariant'] ?? '',
      customerName: data['customerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      warrantyType: data['warrantyType'] ?? 'standard',
      warrantyDurationMonths: data['warrantyDurationMonths'] ?? 12,
      warrantyStartDate: (data['warrantyStartDate'] as Timestamp).toDate(),
      warrantyEndDate: (data['warrantyEndDate'] as Timestamp).toDate(),
      warrantyClaimCount: data['warrantyClaimCount'] ?? 0,
      warrantyRejectedCount: data['warrantyRejectedCount'] ?? 0,
      lastClaimDate: (data['lastClaimDate'] as Timestamp?)?.toDate(),
      lastWarrantyCheck: (data['lastWarrantyCheck'] as Timestamp?)?.toDate(),
      serviceHistory: (data['serviceHistory'] as List<dynamic>?)
              ?.map((e) => ServiceHistoryItem.fromMap(e))
              .toList() ??
          [],
      serviceCertificateURL: data['serviceCertificateURL'],
      location: data['location'] ?? {},
      notes: data['notes'] ?? '',
      latestUpdatedOn: (data['latestUpdatedOn'] as Timestamp?)?.toDate(),
      latestUpdatedBy: data['latestUpdatedBy'],
    );
  }
}
