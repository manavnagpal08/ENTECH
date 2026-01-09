// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/presales_query_model.dart';
import '../../../core/constants/app_constants.dart';
import 'pre_sales_form_screen.dart';
import 'pre_sales_detail_screen.dart';

class PreSalesListScreen extends StatefulWidget {
  final String? initialStatus;
  const PreSalesListScreen({super.key, this.initialStatus});

  @override
  State<PreSalesListScreen> createState() => _PreSalesListScreenState();
}

class _PreSalesListScreenState extends State<PreSalesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExcelService _excelService = ExcelService();
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String _searchQuery = '';
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus ?? 'All';
  }
  
  void _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      if (!mounted) return;
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parsing Excel...')));
        
        List<int> bytes;
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes!;
        } else if (result.files.single.path != null) {
           throw Exception("File data not available. Please retry.");
        } else {
           throw Exception("File not readable.");
        }

        final queries = await _excelService.parsePreSalesExcel(bytes);
        
        final batch = _firestore.batch();
        for (var q in queries) {
          final docRef = _firestore.collection(FirestoreCollections.preSalesQueries).doc(q.id);
          batch.set(docRef, q.toMap());
        }
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported ${queries.length} queries')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const PreSalesFormScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('New Query'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header / Filter Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text("Pre-Sales Queries", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                     // Month Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        items: List.generate(12, (index) {
                          final date = DateTime(DateTime.now().year, DateTime.now().month - index, 1);
                          final str = DateFormat('MMMM yyyy').format(date);
                          return DropdownMenuItem(value: str, child: Text(str));
                        }), 
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _importExcel,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Import'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search & Filter Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search Company, Customer, or Details...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('pending', label: 'New'),
                            _buildFilterChip('proposal_sent', label: 'Sent'),
                            _buildFilterChip('accepted', label: 'Won'),
                            _buildFilterChip('rejected', label: 'Lost'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // List Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(FirestoreCollections.preSalesQueries)
                  .orderBy('queryReceivedDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // Client-side Filtering
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['queryReceivedDate'] as Timestamp).toDate();
                  
                  // 1. Month Filter
                  if (DateFormat('MMMM yyyy').format(date) != _selectedMonth) return false;
                  
                  final q = PreSalesQuery.fromSnapshot(doc);
                  
                  // 2. Status Filter
                  if (_statusFilter != 'All' && q.proposalStatus != _statusFilter) return false;

                  // 3. Search Filter
                  if (_searchQuery.isNotEmpty) {
                    final search = _searchQuery.toLowerCase();
                    final matches = (q.customerName ?? '').toLowerCase().contains(search) ||
                                    (q.company ?? '').toLowerCase().contains(search) ||
                                    (q.productQueryDescription ?? '').toLowerCase().contains(search) ||
                                    q.location.values.any((v) => v.toString().toLowerCase().contains(search));
                    if (!matches) return false;
                  }
                  
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text("No queries found matching your filters.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final query = PreSalesQuery.fromSnapshot(docs[index]);
                    return _buildQueryCard(query);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, {String? label}) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label ?? value),
        onSelected: (v) => setState(() => _statusFilter = value),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildQueryCard(PreSalesQuery query) {
    final color = _getStatusColor(query.proposalStatus);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreSalesDetailScreen(query: query))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Status Strip
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 16),
              
              // Main Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text((query.company ?? '').isNotEmpty ? query.company! : (query.customerName ?? 'Unknown'), 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (query.followUpReminderTomorrow) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Admin Follow-up', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(query.productQueryDescription ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, 
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text("${query.location['city'] ?? '-'}, ${query.location['state'] ?? '-'}", 
                             style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM').format(query.queryReceivedDate), 
                             style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
              
              // Right: Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(query.proposalStatus).toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    if (status == 'pending') return 'New';
    if (status == 'proposal_sent') return 'Sent';
    if (status == 'accepted') return 'Won';
    if (status == 'rejected') return 'Lost';
    return status;
  }

  Color _getStatusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'proposal_sent') return Colors.blue;
    if (status == 'rejected') return Colors.red;
    return Colors.orange; // Pending/New
  }
}
