import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import '../providers/booking_provider.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final _roomTypeController = TextEditingController(text: 'سينجل');
  final _nightsController = TextEditingController(text: '1');
  List<Map<String, dynamic>> _results = [];

  void _compare() {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    if (hotelProvider.hotels.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب إضافة فنادق أولاً')));
      return;
    }

    try {
      final results = bookingProvider.comparePrices(
        hotelProvider.hotels,
        _roomTypeController.text,
        int.parse(_nightsController.text),
      );
      setState(() => _results = results);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء المقارنة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة الأسعار')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomTypeController,
                    decoration: const InputDecoration(labelText: 'نوع الغرفة'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _nightsController,
                    decoration: const InputDecoration(labelText: 'عدد الليالي'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _compare,
              icon: const Icon(Icons.compare),
              label: const Text('بدء المقارنة'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _results.isEmpty
                      ? const Center(
                        child: Text('أدخل البيانات واضغط على بدء المقارنة'),
                      )
                      : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final isBest = index == 0;
                          return Card(
                            color: isBest ? Colors.green[50] : null,
                            child: ListTile(
                              leading:
                                  isBest
                                      ? const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      )
                                      : const Icon(Icons.hotel),
                              title: Text(result['hotel']),
                              subtitle: Text(
                                'الغرفة: ${result['room']} - ليلة: ${result['perNight']}\$',
                              ),
                              trailing: Text(
                                '${result['total']}\$',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isBest ? Colors.green : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
