import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../models/vault_transaction.dart';

class ExportHelper {
  // --- EXCEL EXPORT ---

  static Future<void> exportBookingsExcel(
    List<Booking> bookings,
    String currency,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Bookings'];
    excel.delete('Sheet1'); // Delete default sheet

    // Header row
    List<CellValue> header = [
      TextCellValue('رقم الحجز'),
      TextCellValue('اسم العميل'),
      TextCellValue('الهاتف'),
      TextCellValue('الفندق'),
      TextCellValue('نوع الغرفة'),
      TextCellValue('التاريخ من'),
      TextCellValue('التاريخ إلى'),
      TextCellValue('الليالي'),
      TextCellValue('الأفراد'),
      TextCellValue('إجمالي الغرفة'),
      TextCellValue('إجمالي الخدمات'),
      TextCellValue('الإجمالي الكلي'),
      TextCellValue('المقدم'),
      TextCellValue('المتبقي'),
    ];
    sheetObject.appendRow(header);

    for (var b in bookings) {
      final totalAmount = b.totalAmount;
      final remaining = totalAmount - b.advancePayment;

      sheetObject.appendRow([
        TextCellValue(b.id.substring(0, 8)),
        TextCellValue(b.customerName),
        TextCellValue(b.customerPhone ?? '-'),
        TextCellValue(b.hotel.name),
        TextCellValue(b.roomType.name),
        TextCellValue(DateFormat('yyyy-MM-dd').format(b.checkInDate)),
        TextCellValue(DateFormat('yyyy-MM-dd').format(b.checkOutDate)),
        IntCellValue(b.numberOfNights),
        IntCellValue(b.numberOfPeople),
        DoubleCellValue(b.roomTotal),
        DoubleCellValue(b.servicesTotal),
        DoubleCellValue(totalAmount),
        DoubleCellValue(b.advancePayment),
        DoubleCellValue(remaining),
      ]);
    }

    await _saveExcel(excel, 'bookings_report');
  }

  static Future<void> exportVaultExcel(
    List<VaultTransaction> transactions,
    String currency,
    double balance,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Vault'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('البيان'),
      TextCellValue('النوع'),
      TextCellValue('المبلغ'),
      TextCellValue('الوصف'),
    ]);

    for (var tx in transactions) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(tx.date)),
        TextCellValue(tx.title),
        TextCellValue(tx.type == TransactionType.deposit ? 'إيداع' : 'سحب'),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.description ?? '-'),
      ]);
    }

    // Add summary row
    sheetObject.appendRow([]);
    sheetObject.appendRow([
      TextCellValue('إجمالي الرصيد الحالي'),
      null,
      null,
      DoubleCellValue(balance),
    ]);

    await _saveExcel(excel, 'vault_report');
  }

  static Future<void> exportCustomersExcel(
    List<Map<String, dynamic>> customers,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Customers'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('اسم العميل'),
      TextCellValue('رقم الهاتف'),
      TextCellValue('البريد الإلكتروني'),
      TextCellValue('عدد الحجوزات'),
    ]);

    for (var c in customers) {
      sheetObject.appendRow([
        TextCellValue(c['name'] ?? ''),
        TextCellValue(c['phone'] ?? ''),
        TextCellValue(c['email'] ?? ''),
        IntCellValue(c['bookingCount'] ?? 0),
      ]);
    }

    await _saveExcel(excel, 'customers_list');
  }

  static Future<void> exportHotelsExcel(List<Hotel> hotels) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Hotels'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('اسم الفندق'),
      TextCellValue('الموقع'),
      TextCellValue('التقييم'),
      TextCellValue('عدد الغرف المتاحة'),
    ]);

    for (var h in hotels) {
      sheetObject.appendRow([
        TextCellValue(h.name),
        TextCellValue(h.location),
        IntCellValue(h.starRating),
        IntCellValue(h.availableRooms.length),
      ]);
    }

    await _saveExcel(excel, 'hotels_list');
  }

  // --- WORD EXPORT (HTML Trick) ---

  static Future<void> exportToWord(
    String title,
    List<String> headers,
    List<List<String>> data,
    String fileName,
  ) async {
    // Word can open HTML files. We generate an HTML table.
    String htmlContent = """
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      body { font-family: 'Arial', sans-serif; }
      table { border-collapse: collapse; width: 100%; direction: rtl; }
      th, td { border: 1px solid black; padding: 8px; text-align: right; }
      th { background-color: #f2f2f2; }
      h1 { text-align: center; }
    </style>
    </head>
    <body>
      <h1>$title</h1>
      <table>
        <thead>
          <tr>
            ${headers.map((h) => "<th>$h</th>").join("")}
          </tr>
        </thead>
        <tbody>
          ${data.map((row) => "<tr>${row.map((cell) => "<td>$cell</td>").join("")}</tr>").join("")}
        </tbody>
      </table>
    </body>
    </html>
    """;

    // UTF-8 BOM to help Word recognize the encoding
    final List<int> bom = [0xEF, 0xBB, 0xBF];
    final List<int> encodedHtml = utf8.encode(htmlContent);
    final List<int> bytes = [...bom, ...encodedHtml];

    await _saveFile(bytes, fileName, 'doc');
  }

  // --- PRIVATE HELPERS ---

  static Future<void> _saveExcel(Excel excel, String fileName) async {
    var bytes = excel.save();
    if (bytes != null) {
      await _saveFile(bytes, fileName, 'xlsx');
    }
  }

  static Future<void> _saveFile(
    List<int> bytes,
    String fileName,
    String extension,
  ) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ التقرير',
      fileName:
          '${fileName}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
    );

    if (outputFile != null) {
      if (!outputFile.toLowerCase().endsWith('.$extension')) {
        outputFile += '.$extension';
      }
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
    }
  }
}
