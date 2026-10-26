import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/booking.dart';
import 'package:intl/intl.dart';

class PdfHelper {
  static Future<void> printBookingReport(
    Booking booking,
    String companyName,
    String? logoPath,
    String currency,
  ) async {
    final pdf = pw.Document();

    final totalAmount = booking.totalAmount;
    final remainingAmount = totalAmount - booking.advancePayment;

    // تحميل الخط العربي لضمان ظهور الكلمات بشكل صحيح
    final font = await PdfGoogleFonts.almaraiRegular();
    final fontBold = await PdfGoogleFonts.almaraiBold();

    // تجهيز اللوجو إذا وجد
    pw.MemoryImage? logoImage;
    if (logoPath != null && File(logoPath).existsSync()) {
      final logoBytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(logoBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // الهيدر: اللوجو واسم الشركة
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'تقرير حجز فندقي',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (logoImage != null)
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(logoImage),
                      ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // بيانات العميل الأساسية
                pw.Text(
                  'بيانات العميل:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('اسم العميل: ${booking.customerName}'),
                    if (booking.customerPhone != null &&
                        booking.customerPhone!.isNotEmpty)
                      pw.Text('رقم الهاتف: ${booking.customerPhone}'),
                    if (booking.customerEmail != null &&
                        booking.customerEmail!.isNotEmpty)
                      pw.Text('البريد: ${booking.customerEmail}'),
                  ],
                ),
                pw.SizedBox(height: 30),

                // جدول بيانات الحجز
                pw.Text(
                  'تفاصيل الحجز:',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue900,
                  ),
                  cellAlignment: pw.Alignment.centerRight,
                  headers: ['التفاصيل', 'البيان'],
                  data: [
                    [booking.hotel.name, 'الفندق'],
                    [booking.hotel.location, 'موقع الفندق'],
                    [booking.roomType.name, 'نوع الغرفة'],
                    ['${booking.numberOfNights}', 'عدد الليالي'],
                    [
                      DateFormat('yyyy-MM-dd').format(booking.checkInDate),
                      'تاريخ الوصول',
                    ],
                    [
                      DateFormat('yyyy-MM-dd').format(booking.checkOutDate),
                      'تاريخ المغادرة',
                    ],
                    ['${booking.numberOfPeople}', 'عدد الأفراد'],
                  ],
                ),
                pw.SizedBox(height: 30),

                // الخدمات الإضافية إذا وجدت
                if (booking.extraServices.isNotEmpty) ...[
                  pw.Text(
                    'الخدمات الإضافية:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue700,
                    ),
                    cellAlignment: pw.Alignment.centerRight,
                    headers: ['السعر', 'الخدمة'],
                    data:
                        booking.extraServices
                            .map((s) => ['$currency${s.price}', s.name])
                            .toList(),
                  ),
                  pw.SizedBox(height: 30),
                ],

                // الملخص المالي
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow(
                        'سعر الغرفة (${booking.numberOfNights} ليالي × ${booking.numberOfPeople} أفراد)',
                        '$currency${booking.roomTotal}',
                      ),
                      if (booking.extraServices.isNotEmpty)
                        _buildSummaryRow(
                          'إجمالي الخدمات الإضافية',
                          '$currency${booking.servicesTotal}',
                        ),
                      pw.Divider(),
                      _buildSummaryRow(
                        'الإجمالي الكلي',
                        '$currency${totalAmount.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      if (booking.advancePayment > 0) ...[
                        _buildSummaryRow(
                          'المقدم المدفوع',
                          '$currency${booking.advancePayment}',
                        ),
                        _buildSummaryRow(
                          'المتبقي',
                          '$currency${remainingAmount.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                      pw.Divider(),
                      _buildSummaryRow(
                        'السعر للفرد',
                        '$currency${(totalAmount / booking.numberOfPeople).toStringAsFixed(2)}',
                      ),
                      if (booking.numberOfPeople >= 2 &&
                          !(booking.roomType.name.toLowerCase().contains(
                                'تريبل',
                              ) ||
                              booking.roomType.name.toLowerCase().contains(
                                'triple',
                              )))
                        _buildSummaryRow(
                          'السعر للفردين',
                          '$currency${(totalAmount / booking.numberOfPeople * 2).toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                ),

                pw.Spacer(),
                // تذييل الصفحة
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'تاريخ الطباعة: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                    pw.Text(
                      'نظام إدارة الحجوزات الفندقية',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await _saveOrPrintPdf(pdf, booking.customerName);
  }

  static Future<void> _saveOrPrintPdf(
    pw.Document pdf,
    String customerName,
  ) async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ تقرير الحجز',
          fileName: 'حجز_$customerName.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          if (!outputFile.toLowerCase().endsWith('.pdf')) {
            outputFile += '.pdf';
          }
          final file = File(outputFile);
          await file.writeAsBytes(await pdf.save());
          return;
        }
      }

      // fallback to printing if file picker fails or on mobile
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'حجز_$customerName.pdf',
      );
    } catch (e) {
      // fallback to printing on error
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'حجز_$customerName.pdf',
      );
    }
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 12,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 12,
              color: isTotal ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
