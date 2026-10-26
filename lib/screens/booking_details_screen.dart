import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../providers/settings_provider.dart';
import '../utils/pdf_helper.dart';

class BookingDetailsScreen extends StatelessWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);
    final currency = settingsProvider.currencySymbol;
    final taxPercentage = settingsProvider.taxPercentage;

    final totalAmount = booking.totalAmount;
    final remaining = totalAmount - booking.advancePayment;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('تفاصيل الحجز'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed:
                  () => PdfHelper.printBookingReport(
                    booking,
                    settingsProvider.companyName,
                    settingsProvider.logoPath,
                    currency,
                  ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Customer Name and Status
              _buildHeaderCard(totalAmount, booking.advancePayment),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column: Customer & Booking Info
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildInfoSection(
                          title: 'بيانات العميل',
                          icon: Icons.person_outline,
                          items: [
                            _buildInfoRow('الاسم', booking.customerName),
                            if (booking.customerPhone?.isNotEmpty == true)
                              _buildInfoRow(
                                'رقم الهاتف',
                                booking.customerPhone!,
                              ),
                            if (booking.customerEmail?.isNotEmpty == true)
                              _buildInfoRow(
                                'البريد الإلكتروني',
                                booking.customerEmail!,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfoSection(
                          title: 'بيانات الإقامة',
                          icon: Icons.hotel_outlined,
                          items: [
                            _buildInfoRow('الفندق', booking.hotel.name),
                            _buildInfoRow('الموقع', booking.hotel.location),
                            _buildInfoRow('نوع الغرفة', booking.roomType.name),
                            _buildInfoRow(
                              'عدد الليالي',
                              '${booking.numberOfNights} ليالي',
                            ),
                            _buildInfoRow(
                              'تاريخ الوصول',
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(booking.checkInDate),
                            ),
                            _buildInfoRow(
                              'تاريخ المغادرة',
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(booking.checkOutDate),
                            ),
                            _buildInfoRow(
                              'عدد الأفراد',
                              '${booking.numberOfPeople} أفراد',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Left Column: Financial Summary
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildFinancialSection(
                          currency,
                          totalAmount,
                          remaining,
                        ),
                        const SizedBox(height: 24),
                        if (booking.extraServices.isNotEmpty)
                          _buildServicesSection(currency),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double total, double paid) {
    final isFullyPaid = (total - paid).abs() < 0.01;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.customerName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'رقم الحجز: ${booking.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isFullyPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFullyPaid ? 'مدفوع بالكامل' : 'بانتظار السداد',
              style: TextStyle(
                color: isFullyPaid ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1E5BB8), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5BB8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(
    String currency,
    double total,
    double remaining,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E5BB8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الملخص المالي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildFinancialRow(
            'سعر الغرفة (${booking.numberOfNights} ليالي × ${booking.numberOfPeople} أفراد)',
            '$currency${booking.roomTotal}',
            Colors.white70,
          ),
          if (booking.extraServices.isNotEmpty)
            _buildFinancialRow(
              'الخدمات',
              '$currency${booking.servicesTotal}',
              Colors.white70,
            ),
          const Divider(color: Colors.white24, height: 24),
          _buildFinancialRow(
            'الإجمالي',
            '$currency${total.toStringAsFixed(2)}',
            Colors.white,
            isBold: true,
          ),
          _buildFinancialRow(
            'المدفوع',
            '$currency${booking.advancePayment.toStringAsFixed(2)}',
            Colors.greenAccent,
          ),
          _buildFinancialRow(
            'المتبقي',
            '$currency${remaining.toStringAsFixed(2)}',
            Colors.orangeAccent,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: isBold ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الخدمات المضافة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          ...booking.extraServices.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 14)),
                  Text(
                    '$currency${s.price}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
