import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../providers/booking_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vault_provider.dart';
import '../models/vault_transaction.dart';
import '../models/booking.dart';
import 'booking_details_screen.dart';

class RemainingPaymentsScreen extends StatelessWidget {
  const RemainingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);
    final vaultProvider = Provider.of<VaultProvider>(context, listen: false);

    final currency = settingsProvider.currencySymbol;

    // تصفية الحجوزات التي لها مبالغ متبقية والتأكد من عدم التكرار باستخدام المعرف (ID)
    final Map<String, Booking> uniqueBookings = {};
    for (var b in bookingProvider.bookings) {
      final totalAmount = b.totalAmount;
      if ((totalAmount - b.advancePayment) > 0.01) {
        // إذا كان الحجز موجوداً بالفعل، نحتفظ بالنسخة التي بها دفع أكثر (الأحدث غالباً)
        if (uniqueBookings.containsKey(b.id)) {
          if (b.advancePayment > uniqueBookings[b.id]!.advancePayment) {
            uniqueBookings[b.id] = b;
          }
        } else {
          uniqueBookings[b.id] = b;
        }
      }
    }
    final bookingsWithRemaining = uniqueBookings.values.toList();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('متبقي الدفع'), centerTitle: true),
        body:
            bookingsWithRemaining.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد مبالغ متبقية حالياً',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookingsWithRemaining.length,
                  itemBuilder: (context, index) {
                    final booking = bookingsWithRemaining[index];
                    final totalAmount = booking.totalAmount;
                    final remaining = totalAmount - booking.advancePayment;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الجزء العلوي: معلومات الحجز (قابلة للنقر للذهاب للتفاصيل)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BookingDetailsScreen(
                                        booking: booking,
                                      ),
                                ),
                              );
                            },
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
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
                                              'هاتف: ${booking.customerPhone}',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'متبقي: $currency${remaining.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'الفندق: ${booking.hotel.name} - ${booking.roomType.name}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'تاريخ الوصول: ${DateFormat('yyyy-MM-dd').format(booking.checkInDate)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          // الجزء السفلي: أزرار التحكم (خارج الـ InkWell لضمان الاستجابة)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الإجمالي: $currency${totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'المدفوع: $currency${booking.advancePayment.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  key: ValueKey('pay_${booking.id}'),
                                  onPressed:
                                      () => _showPaymentDialog(
                                        context,
                                        booking,
                                        remaining,
                                        bookingProvider,
                                        vaultProvider,
                                        currency,
                                      ),
                                  icon: const Icon(Icons.payment),
                                  label: const Text('تسديد المتبقي'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E5BB8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    Booking booking,
    double remaining,
    BookingProvider bookingProvider,
    VaultProvider vaultProvider,
    String currency,
  ) {
    final controller = TextEditingController(
      text: remaining.toStringAsFixed(2),
    );
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('تسديد مبلغ'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'المبلغ المتبقي لحجز ${booking.customerName} هو $currency${remaining.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'المبلغ المراد تسديده الآن',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          enabled: !isLoading,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  final amount =
                                      double.tryParse(controller.text) ?? 0.0;
                                  if (amount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('الرجاء إدخال مبلغ صحيح'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (amount > remaining + 0.01) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'المبلغ المدخل أكبر من المتبقي',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => isLoading = true);

                                  try {
                                    // تحديث الحجز (زيادة المقدم) باستخدام copyWith لضمان عدم فقدان أي بيانات
                                    final updatedBooking = booking.copyWith(
                                      advancePayment:
                                          booking.advancePayment + amount,
                                    );

                                    await bookingProvider.updateBooking(
                                      updatedBooking,
                                    );

                                    // إضافة العملية للخزنة
                                    await vaultProvider.addTransaction(
                                      'تسديد متبقي: ${booking.customerName}',
                                      amount,
                                      TransactionType.deposit,
                                      description:
                                          'تسديد متبقي حجز فندق ${booking.hotel.name}',
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم تسديد المبلغ وإيداعه في الخزنة بنجاح',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isLoading = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('حدث خطأ: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('تأكيد الدفع'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
