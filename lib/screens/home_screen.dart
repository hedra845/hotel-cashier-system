import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../providers/hotel_provider.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreenContent();
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final hotelProvider = Provider.of<HotelProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);

    final bookings = bookingProvider.bookings;
    final totalRevenue = bookingProvider.totalRevenue;
    final hotelsCount = hotelProvider.hotels.length;
    final currency = settingsProvider.currencySymbol;
    final todayBookings =
        bookings.where((b) {
          final now = DateTime.now();
          return b.checkInDate.year == now.year &&
              b.checkInDate.month == now.month &&
              b.checkInDate.day == now.day;
        }).length;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5BB8),
                ),
              ),
              const SizedBox(height: 32),

              // Top Stats Cards
              Row(
                children: [
                  _buildStatCard(
                    'إجمالي الأرباح',
                    '$currency${totalRevenue.toStringAsFixed(0)}',
                    Icons.monetization_on,
                    const Color(0xFFFFF4E5),
                    const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'حجوزات اليوم',
                    todayBookings.toString(),
                    Icons.book_online,
                    const Color(0xFFE8F5E9),
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'إجمالي الفنادق',
                    hotelsCount.toString(),
                    Icons.hotel,
                    const Color(0xFFE3F2FD),
                    const Color(0xFF2196F3),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              const Text(
                'آخر الحجوزات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Recent Bookings List
              if (bookings.isEmpty)
                _buildEmptyState()
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final booking = bookings[bookings.length - 1 - index];
                      return _buildBookingItem(context, booking);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B), // Dark slate color
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, booking) {
    final currency =
        Provider.of<SystemSettingsProvider>(
          context,
          listen: false,
        ).currencySymbol;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Icon on the right (actually visual right when RTL is on)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF1E5BB8),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Customer and Hotel Info in middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.hotel.name} - ${booking.roomType.name}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          // Price on the left
          Text(
            '$currency${booking.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFF2ECC71), // Vibrant green
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد حجوزات بعد',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
