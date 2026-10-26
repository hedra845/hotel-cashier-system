import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/pdf_helper.dart';
import '../utils/export_helper.dart';
import 'booking_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);
    final bookings = bookingProvider.bookings;
    final currency = settingsProvider.currencySymbol;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحجوزات الحالية'),
          actions: [
            if (bookings.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.table_view, color: Colors.green),
                tooltip: 'تصدير Excel',
                onPressed:
                    () => ExportHelper.exportBookingsExcel(bookings, currency),
              ),
              IconButton(
                icon: const Icon(Icons.description, color: Colors.blue),
                tooltip: 'تصدير Word',
                onPressed: () {
                  final List<String> headers = [
                    'العميل',
                    'الهاتف',
                    'الفندق',
                    'الغرفة',
                    'من',
                    'إلى',
                    'المبلغ',
                  ];
                  final List<List<String>> data =
                      bookings
                          .map(
                            (b) => [
                              b.customerName,
                              b.customerPhone ?? '-',
                              b.hotel.name,
                              b.roomType.name,
                              DateFormat('yyyy-MM-dd').format(b.checkInDate),
                              DateFormat('yyyy-MM-dd').format(b.checkOutDate),
                              '$currency${b.totalAmount}',
                            ],
                          )
                          .toList();
                  ExportHelper.exportToWord(
                    'تقرير الحجوزات',
                    headers,
                    data,
                    'bookings_report',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body:
            bookings.isEmpty
                ? const Center(child: Text('لا توجد حجوزات بعد'))
                : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final checkIn = DateFormat(
                      'yyyy-MM-dd',
                    ).format(booking.checkInDate);
                    final checkOut = DateFormat(
                      'yyyy-MM-dd',
                    ).format(booking.checkOutDate);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    BookingDetailsScreen(booking: booking),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking.customerName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (booking.customerPhone != null &&
                                            booking.customerPhone!.isNotEmpty)
                                          Text(
                                            booking.customerPhone!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        if (booking.customerEmail != null &&
                                            booking.customerEmail!.isNotEmpty)
                                          Text(
                                            booking.customerEmail!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$currency${booking.totalAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (booking.advancePayment > 0)
                                        Text(
                                          'المتبقي: $currency${booking.remainingAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.print_outlined,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed:
                                        () => PdfHelper.printBookingReport(
                                          booking,
                                          settingsProvider.companyName,
                                          settingsProvider.logoPath,
                                          currency,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.email_outlined,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final customerEmail =
                                          booking.customerEmail;
                                      if (customerEmail == null ||
                                          customerEmail.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'هذا العميل ليس لديه بريد إلكتروني مسجل',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      final subject = Uri.encodeComponent(
                                        'فاتورة حجز: ${booking.customerName}',
                                      );
                                      final body = Uri.encodeComponent(
                                        'عزيزي ${booking.customerName}،\n\n'
                                        'مرفق تفاصيل حجزكم في فندق ${booking.hotel.name}:\n'
                                        'تاريخ الوصول: ${DateFormat('yyyy-MM-dd').format(booking.checkInDate)}\n'
                                        'تاريخ المغادرة: ${DateFormat('yyyy-MM-dd').format(booking.checkOutDate)}\n'
                                        'نوع الغرفة: ${booking.roomType.name}\n'
                                        'المبلغ الإجمالي: $currency${booking.totalAmount}\n'
                                        'المقدم المدفوع: $currency${booking.advancePayment}\n'
                                        'المتبقي للسداد: $currency${booking.remainingAmount}\n\n'
                                        'شكراً لاختياركم خدماتنا.\n'
                                        '${settingsProvider.companyName}',
                                      );

                                      final url = Uri.parse(
                                        'mailto:$customerEmail?subject=$subject&body=$body',
                                      );
                                      try {
                                        if (!await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        )) {
                                          throw 'Could not launch $url';
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          _showEmailFallbackDialog(
                                            context,
                                            customerEmail,
                                            Uri.decodeComponent(subject),
                                            Uri.decodeComponent(body),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => Directionality(
                                              textDirection:
                                                  ui.TextDirection.rtl,
                                              child: AlertDialog(
                                                title: const Text(
                                                  'إلغاء الحجز',
                                                ),
                                                content: Text(
                                                  'هل أنت متأكد من إلغاء حجز ${booking.customerName}؟',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('رجوع'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      bookingProvider
                                                          .removeBooking(
                                                            booking.id,
                                                          );
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'تأكيد الإلغاء',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(
                                    Icons.hotel_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking.hotel.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$checkIn - $checkOut',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${booking.numberOfNights} ليالي',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  void _showEmailFallbackDialog(
    BuildContext context,
    String email,
    String subject,
    String body,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تفاصيل الفاتورة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعذر فتح تطبيق البريد تلقائياً. يمكنك نسخ النص التالي وإرساله يدوياً:',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'إلى: $email',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الموضوع: $subject',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    SelectableText(body),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ نص الرسالة')),
                    );
                  },
                  child: const Text('نسخ النص'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
    );
  }
}
