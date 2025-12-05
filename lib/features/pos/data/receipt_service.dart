import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service for generating and printing POS receipts
class ReceiptService {
  /// Store information - customize these as needed
  static const String storeName = 'MY STORE';
  static const String storeAddress = '123 Business Street, City, State 12345';
  static const String storePhone = 'Tel: (555) 123-4567';
  static const String storeTaxId = 'Tax ID: 123-456-789';

  /// Generate a PDF receipt for a completed order
  static Future<pw.Document> generateReceipt({
    required String orderNumber,
    required DateTime orderDate,
    required List items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    String? customerName,
  }) async {
    final pdf = pw.Document();
    
    // Load a Unicode-compatible font to avoid Helvetica warnings
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Store Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      storeAddress,
                      style: pw.TextStyle(font: font, fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      storePhone,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.Text(
                      storeTaxId,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Order Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order: $orderNumber', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text(
                    _formatDateTime(orderDate),
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              if (customerName != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Customer: $customerName', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              pw.Text('Payment: ${paymentMethod.toUpperCase()}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text('Item', style: pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Price', style: pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(),

              // Items List
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        item.product.name,
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        item.quantity.toInt().toString(),
                        style: pw.TextStyle(font: font, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '\$${item.product.salePrice.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Totals
              _buildTotalRow('Subtotal:', subtotal, font),
              _buildTotalRow('Tax:', tax, font),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for shopping!',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Please come again',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Print the receipt
  static Future<void> printReceipt({
    required String orderNumber,
    required DateTime orderDate,
    required List items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    String? customerName,
  }) async {
    final pdf = await generateReceipt(
      orderNumber: orderNumber,
      orderDate: orderDate,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      customerName: customerName,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// Share or save the receipt as PDF
  static Future<void> shareReceipt({
    required String orderNumber,
    required DateTime orderDate,
    required List items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    String? customerName,
  }) async {
    final pdf = await generateReceipt(
      orderNumber: orderNumber,
      orderDate: orderDate,
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      customerName: customerName,
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt_$orderNumber.pdf',
    );
  }

  /// Helper method to build total rows
  static pw.Widget _buildTotalRow(String label, double amount, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('\$${amount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Format date time for receipt
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
