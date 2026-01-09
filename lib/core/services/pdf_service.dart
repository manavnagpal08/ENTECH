import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import '../../data/models/product_model.dart';

class PdfService {
  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      // 1. Try Dynamic Logo from Firestore (Admin Settings)
       try {
         final doc = await FirebaseFirestore.instance.collection('settings').doc('global').get();
         if (doc.exists && doc.data() != null && doc.data()!['logoUrl'] != null) {
            // Short timeout to fail fast if URL is bad
            return await networkImage(doc.data()!['logoUrl']).timeout(const Duration(seconds: 4));
         }
       } catch (e) {
         debugPrint('PDF Logo: Firestore fetch failed: $e');
       }

      // 2. Fallback: Return NULL to trigger Text Display.
      // We strictly do NOT load local assets or other network images to prevent hanging.
      return null;
    } catch (e) {
      debugPrint('PDF Logo: Critical error: $e');
      return null;
    }
  }

  Future<void> generateServiceTicketReport(ServiceTicket ticket, ProductModel product) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();
    // Use Standard Fonts (Helvetica) for instant performance -> No Network Fetch
    final font = pw.Font.helvetica(); 
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _buildHeader(logoImage),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
               _buildTitle('Service Ticket Report'),
               _buildWarrantyChip(ticket.warrantyStatus),
            ]
          ),
          pw.Divider(color: PdfColors.blueGrey200),
          pw.SizedBox(height: 10),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
               pw.Expanded(
                 child: _buildSection('Customer Details', [
                    'Name: ${product.customerName}',
                    'Phone: ${product.phoneNumber}',
                    'Email: ${product.email}',
                    if (product.location['city'] != null)
                      'Loc: ${product.location['city']}, ${product.location['state']}',
                  ]),
               ),
               pw.Expanded(
                 child: _buildSection('Product Information', [
                    'Product: ${product.productName}',
                    'Model: ${product.modelOrVariant}',
                    'Serial No: ${product.serialNumber}',
                    'Purchased: ${product.purchaseDate.toString().split(' ')[0]}',
                  ]),
               ),
               pw.Expanded(
                 child: _buildSection('Ticket Info', [
                    'Ticket ID: ${ticket.id}',
                    'Status: ${ticket.status.toUpperCase()}',
                    'Received: ${ticket.issueReceivedDate.toString().split(' ')[0]}',
                    'SLA: ${ticket.serviceSLAReplyDays} Days',
                  ]),
               ),
            ]
          ),
          
          pw.SizedBox(height: 20),
          _buildSection('Issue Description', [ticket.issueDescription]),
          pw.SizedBox(height: 10),
          
          if (ticket.usedParts.isNotEmpty) ...[
             pw.Text('Parts Replaced', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
             pw.SizedBox(height: 5),
             _buildPartsTable(ticket.usedParts),
             pw.SizedBox(height: 15),
          ],
          
          _buildSection('Work Summary', [
            ticket.finalServiceSummary ?? 'Service completed as per standard procedure.',
          ]),
          
          pw.SizedBox(height: 10),
           _buildSection('Action Timeline', ticket.actions.map((a) => 
              '${a.date.toString().split(' ')[0]}: ${a.action} by ${a.employeeName}'
           ).toList()),

          pw.SizedBox(height: 20),
          if (ticket.feedbackText != null)
             pw.Container(
               padding: const pw.EdgeInsets.all(10),
               decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
               child: _buildSection('Customer Feedback', [
                 'Rating: ${ticket.rating}/5',
                 '"${ticket.feedbackText}"',
               ]),
             ),
             
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Service_Report_${ticket.id}',
    );
  }

  Future<void> generateWarrantyCertificate(ProductModel product) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();
    // Use Standard Fonts (Helvetica) for instant performance -> No Network Fetch
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _buildHeader(logoImage),
            pw.SizedBox(height: 40),
            pw.Text('WARRANTY CERTIFICATE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Certificate No: ${product.id.length >= 8 ? product.id.substring(0, 8).toUpperCase() : product.id.toUpperCase()}'),
                  pw.SizedBox(height: 10),
                  pw.Text('This certifies that the product below is covered under Envirotech Warranty.'),
                  pw.SizedBox(height: 20),
                  pw.Row(children: [
                    pw.Text('Product: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(product.productName),
                  ]),
                  pw.Row(children: [
                    pw.Text('Serial Number: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(product.serialNumber),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Row(children: [
                    pw.Text('Valid From: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(product.warrantyStartDate.toString().split(' ')[0]),
                  ]),
                  pw.Row(children: [
                    pw.Text('Valid Until: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(product.warrantyEndDate.toString().split(' ')[0]),
                  ]),
                ],
              ),
            ),
             pw.Spacer(),
             _buildFooter(),
          ],
        ),
      ),
    );

     await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Warranty_Cert_${product.serialNumber}',
    );
  }

  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Column(
      children: [
        if (logo != null)
           pw.Image(logo, width: 80, height: 80)
        else
           pw.Text("ENVIROTECH SYSTEM", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        
        pw.SizedBox(height: 10),
        pw.Text(AppStrings.appName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(AppStrings.tagline, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildSection(String title, List<String> lines) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 5),
          ...lines.map((l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  pw.Widget _buildPartsTable(List<UsedPart> parts) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerHeight: 25,
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      headers: ['Part Name', 'Qty', 'Replaced On'],
      data: parts.map((p) => [p.partName, p.qty.toString(), p.replacedOn.toString().split(' ')[0]]).toList(),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text('Service Contact: ${AppStrings.contactPhone}', style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Generated by Envirotech System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ],
    );
  }
  pw.Widget _buildWarrantyChip(String status) {
    final isWarranty = status == 'in_warranty';
    final color = isWarranty ? PdfColors.green : PdfColors.red;
    final bgColor = isWarranty ? PdfColors.green100 : PdfColors.red100;
    
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        isWarranty ? 'IN WARRANTY' : 'OUT OF WARRANTY',
        style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Future<void> generateFullProductHistory(ProductModel product) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogo();
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          _buildHeader(logoImage),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text('PRODUCT LIFECYCLE REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          ),
          pw.SizedBox(height: 20),

          // Product Overview
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildSection('Product Details', [
                    'Name: ${product.productName}',
                    'Model: ${product.modelOrVariant}',
                    'S/N: ${product.serialNumber}',
                    'Warranty: ${product.isWarrantyValid ? "ACTIVE" : "EXPIRED"}',
                  ]),
                ),
                pw.Expanded(
                  child: _buildSection('Customer Details', [
                    'Name: ${product.customerName}',
                    'Phone: ${product.phoneNumber}',
                    'Email: ${product.email}',
                    'Loc: ${product.location['city'] ?? '-'}',
                  ]),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text('Service Timeline', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),

          if (product.serviceHistory.isEmpty)
             pw.Center(child: pw.Text("No service history recorded for this product.", style: const pw.TextStyle(color: PdfColors.grey)))
          else
            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headerHeight: 30,
              cellHeight: 40,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(80), // Date
                1: const pw.FixedColumnWidth(80), // Ticket
                2: const pw.FlexColumnWidth(2),   // Issue/Notes
                3: const pw.FlexColumnWidth(1),   // Parts
              },
              headers: ['Date', 'Ticket ID', 'Issue & Resolution', 'Parts'],
              data: product.serviceHistory.map((h) => [
                h.resolvedOn.toString().split(' ')[0],
                h.ticketId.length > 5 ? '#${h.ticketId.substring(0, 5)}' : '#${h.ticketId}',
                'Issue: ${h.issueDescription}\nNote: ${h.notesSummary}',
                h.partsReplacedSummary.isEmpty ? '-' : h.partsReplacedSummary,
              ]).toList(),
            ),

           pw.Spacer(),
           _buildFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'History_${product.serialNumber}',
    );
  }
}
