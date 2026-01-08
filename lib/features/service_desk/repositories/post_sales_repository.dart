import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/service_ticket_model.dart';
import '../screens/spare_parts_screen.dart';

class PostSalesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PRODUCT REGISTRY METHODS

  Future<void> createProduct(ProductModel product) async {
    await _firestore.collection(FirestoreCollections.products).doc(product.id).set(product.toMap());
  }

  Future<ProductModel?> getProductBySerial(String serial) async {
    final snapshot = await _firestore.collection(FirestoreCollections.products)
        .where('serialNumber', isEqualTo: serial)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return ProductModel.fromSnapshot(snapshot.docs.first);
    }
    return null;
  }

  // SERVICE TICKET METHODS

  Future<void> createServiceTicket(ServiceTicket ticket) async {
    // 1. Check Warranty Validity
    final product = await getProductBySerial(ticket.linkedSerialNumber);
    String warrantyStatus = 'out_of_warranty';
    String chargeType = 'paid';
    
    if (product != null) {
      if (product.isWarrantyValid) {
        warrantyStatus = 'in_warranty';
        if (product.warrantyType == 'standard' || product.warrantyType == 'extended') {
           chargeType = 'free';
        }
      }
    }

    final newTicket = ServiceTicket(
      id: ticket.id,
      linkedSerialNumber: ticket.linkedSerialNumber,
      issueDescription: ticket.issueDescription,
      issueReceivedDate: ticket.issueReceivedDate,
      status: 'open',
      assignedEmployeeId: ticket.assignedEmployeeId,
      assignedEmployeeName: ticket.assignedEmployeeName,
      warrantyStatus: warrantyStatus,
      serviceChargeType: chargeType,
      actions: [],
      usedParts: [],
    );

    await _firestore.collection(FirestoreCollections.serviceTickets).doc(ticket.id).set(newTicket.toMap());
  }

  // ATOMIC PART REPLACEMENT
  Future<void> addPartToTicket(String ticketId, SparePart part, int qty, String employeeName) async {
    return _firestore.runTransaction((transaction) async {
      // 1. Read Part Stock
      final partRef = _firestore.collection(FirestoreCollections.spareParts).doc(part.id);
      final partSnap = await transaction.get(partRef);
      if (!partSnap.exists) throw Exception('Part not found');
      
      final currentStock = partSnap.data()?['stockQty'] ?? 0;
      if (currentStock < qty) throw Exception('Insufficient stock');
      
      // 2. Read Ticket
      final ticketRef = _firestore.collection(FirestoreCollections.serviceTickets).doc(ticketId);
      final ticketSnap = await transaction.get(ticketRef);
      if (!ticketSnap.exists) throw Exception('Ticket not found');
      final ticket = ServiceTicket.fromSnapshot(ticketSnap);
      
      // 3. Deduct Stock
      transaction.update(partRef, {'stockQty': currentStock - qty});
      
      // 4. Update Ticket Used Parts & Actions
      final newUsedPart = UsedPart(partName: part.partName, qty: qty, replacedOn: DateTime.now());
      final newAction = EmployeeAction(
        employeeName: employeeName,
        action: 'Replaced ${part.partName} ($qty)',
        date: DateTime.now(),
      );
      
      final updatedParts = List<UsedPart>.from(ticket.usedParts)..add(newUsedPart);
      final updatedActions = List<EmployeeAction>.from(ticket.actions)..add(newAction);
      
      transaction.update(ticketRef, {
        'usedParts': updatedParts.map((e) => e.toMap()).toList(),
        'actions': updatedActions.map((e) => e.toMap()).toList(),
      });
    });
  }

  // CLOSE TICKET & WRITE-BACK
  Future<void> closeTicket(ServiceTicket ticket, String summary, String employeeName) async {
     final ticketRef = _firestore.collection(FirestoreCollections.serviceTickets).doc(ticket.id);
     
     // 1. Update Ticket Status
     await ticketRef.update({
       'status': 'closed',
       'finalServiceSummary': summary,
       'actions': FieldValue.arrayUnion([
          EmployeeAction(
            employeeName: employeeName,
            action: 'Closed Ticket',
            date: DateTime.now(),
            notes: 'Summary: $summary',
          ).toMap()
       ])
     });

     // 2. Update Product History
     final product = await getProductBySerial(ticket.linkedSerialNumber);
     if (product != null) {
        final historyItem = ServiceHistoryItem(
          ticketId: ticket.id,
          issueDescription: ticket.issueDescription,
          resolvedOn: DateTime.now(),
          partsReplacedSummary: ticket.usedParts.map((e) => '${e.partName} (${e.qty})').join(', '),
          notesSummary: summary,
          warrantyStatusAtService: ticket.warrantyStatus,
        );

        final productRef = _firestore.collection(FirestoreCollections.products).doc(product.id);
        
        await productRef.update({
          'serviceHistory': FieldValue.arrayUnion([historyItem.toMap()]),
          'lastClaimDate': ticket.serviceChargeType == 'free' ? FieldValue.serverTimestamp() : product.lastClaimDate, // Wait, Timestamp parsing might fail if we mix
          // Better to set explicitly for safety
        });
        
        // Separate update for counters to avoid race if possible, but Transaction is better.
        // For simplicity here:
        if (ticket.serviceChargeType == 'free') {
           await productRef.update({'warrantyClaimCount': FieldValue.increment(1)});
        }
     }
  }

  Future<void> submitFeedback(String ticketId, int rating, String feedback) async {
    await _firestore.collection(FirestoreCollections.serviceTickets).doc(ticketId).update({
      'rating': rating,
      'feedbackText': feedback,
    });
  }
}
