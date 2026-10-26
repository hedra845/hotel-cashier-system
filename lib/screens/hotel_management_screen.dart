import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hotel_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/export_helper.dart';
import 'add_hotel_screen.dart';

class HotelManagementScreen extends StatefulWidget {
  const HotelManagementScreen({super.key});

  @override
  State<HotelManagementScreen> createState() => _HotelManagementScreenState();
}

class _HotelManagementScreenState extends State<HotelManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);

    final hotels =
        hotelProvider.hotels.where((hotel) {
          final name = hotel.name.toLowerCase();
          final location = hotel.location.toLowerCase();
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || location.contains(query);
        }).toList();

    final currency = settingsProvider.currencySymbol;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الفنادق'),
          actions: [
            if (hotels.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.table_view, color: Colors.green),
                tooltip: 'تصدير Excel',
                onPressed: () => ExportHelper.exportHotelsExcel(hotels),
              ),
              IconButton(
                icon: const Icon(Icons.description, color: Colors.blue),
                tooltip: 'تصدير Word',
                onPressed: () {
                  final List<String> headers = [
                    'الفندق',
                    'الموقع',
                    'التقييم',
                    'الغرف',
                  ];
                  final List<List<String>> data =
                      hotels
                          .map(
                            (h) => [
                              h.name,
                              h.location,
                              '${h.starRating} نجوم',
                              '${h.availableRooms.length}',
                            ],
                          )
                          .toList();
                  ExportHelper.exportToWord(
                    'قائمة الفنادق',
                    headers,
                    data,
                    'hotels_list',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فندق باسمه أو موقعه...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ),
        body:
            hotels.isEmpty
                ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'لا توجد فنادق مضافة بعد'
                        : 'لا توجد نتائج مطابقة لبحثك',
                  ),
                )
                : ListView.builder(
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading:
                            hotel.imagePath != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(hotel.imagePath!),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.hotel,
                                    color: Colors.grey,
                                  ),
                                ),
                        title: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        subtitle: Text(
                          '${hotel.starRating} نجوم - ${hotel.location}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.right,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${hotel.availableRooms.length} غرف',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            AddHotelScreen(hotel: hotel),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                _showDeleteDialog(
                                  context,
                                  hotel,
                                  hotelProvider,
                                );
                              },
                            ),
                          ],
                        ),
                        onTap:
                            () =>
                                _showHotelRoomsDialog(context, hotel, currency),
                      ),
                    );
                  },
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddHotelScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showHotelRoomsDialog(BuildContext context, hotel, String currency) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('أسعار غرف ${hotel.name}'),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hotel.availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = hotel.availableRooms[index];
                    return ListTile(
                      title: Text(room.name),
                      trailing: Text(
                        '$currency${room.pricePerNight}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteDialog(BuildContext context, hotel, hotelProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف الفندق'),
            content: Text('هل أنت متأكد من حذف ${hotel.name}؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  hotelProvider.removeHotel(hotel.id);
                  Navigator.pop(context);
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
