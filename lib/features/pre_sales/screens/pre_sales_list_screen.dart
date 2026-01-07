import 'pre_sales_form_screen.dart';

// ... inside class
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PreSalesFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
// ...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/presales_query_model.dart';
import '../../../core/constants/app_constants.dart';

class PreSalesListScreen extends StatefulWidget {
  const PreSalesListScreen({super.key});

  @override
  State<PreSalesListScreen> createState() => _PreSalesListScreenState();
}

class _PreSalesListScreenState extends State<PreSalesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExcelService _excelService = ExcelService();
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  
  void _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parsing Excel...')));
        final queries = await _excelService.parsePreSalesExcel(result.files.single.path!);
        
        // Batch write to Firestore
        final batch = _firestore.batch();
        for (var q in queries) {
          final docRef = _firestore.collection(FirestoreCollections.preSalesQueries).doc(q.id);
          batch.set(docRef, q.toMap());
        }
        await batch.commit();
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported ${queries.length} queries')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Form
          // Navigator.push...
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search queries...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedMonth,
                  underline: const SizedBox(),
                  items: List.generate(12, (index) {
                    final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                    final str = DateFormat('MMMM yyyy').format(date);
                    return DropdownMenuItem(value: str, child: Text(str));
                  }), 
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _importExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Excel'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(FirestoreCollections.preSalesQueries)
                  .orderBy('queryReceivedDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['queryReceivedDate'] as Timestamp).toDate();
                  return DateFormat('MMMM yyyy').format(date) == _selectedMonth;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No queries found for this month'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final query = PreSalesQuery.fromSnapshot(docs[index]);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(query.proposalStatus),
                          child: Icon(_getStatusIcon(query.proposalStatus), color: Colors.white, size: 20),
                        ),
                        title: Text(query.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${query.productQueryDescription}\nReceived: ${DateFormat('dd MMM').format(query.queryReceivedDate)}'),
                        isThreeLine: true,
                        trailing: query.followUpReminderTomorrow 
                            ? const Chip(label: Text('Follow-up Due'), backgroundColor: Colors.orangeAccent)
                            : null,
                        onTap: () {
                          // View Detail
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'proposal_sent') return Colors.blue;
    if (status == 'rejected') return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'accepted') return Icons.check;
    if (status == 'proposal_sent') return Icons.send;
    if (status == 'rejected') return Icons.close;
    return Icons.new_releases;
  }
}
