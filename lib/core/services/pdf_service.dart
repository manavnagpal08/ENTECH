
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/app_constants.dart';
import '../../data/models/service_ticket_model.dart';
import '../../data/models/product_model.dart';

class PdfService {
  Future<void> generateServiceTicketReport(ServiceTicket ticket, ProductModel product) async {
    final pdf = pw.Document();
    final logoImage = await imageFromAssetBundle(AppAssets.logo);
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

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
    final logoImage = await imageFromAssetBundle(AppAssets.logo);
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();


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
                  pw.Text('Certificate No: ${product.id.substring(0, 8).toUpperCase()}'),
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

  pw.Widget _buildHeader(pw.ImageProvider logo) {
    return pw.Column(
      children: [
        pw.Image(logo, width: 80, height: 80),
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
}
