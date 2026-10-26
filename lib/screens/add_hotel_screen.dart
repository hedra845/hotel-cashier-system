import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/hotel.dart';
import '../models/room_type.dart';
import '../providers/hotel_provider.dart';
import '../providers/settings_provider.dart';

class AddHotelScreen extends StatefulWidget {
  final Hotel? hotel;
  const AddHotelScreen({super.key, this.hotel});

  @override
  State<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late int _starRating;
  List<RoomType> _roomTypes = [];
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hotel?.name ?? '');
    _locationController = TextEditingController(
      text: widget.hotel?.location ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.hotel?.totalCapacity.toString() ?? '0',
    );
    _starRating = widget.hotel?.starRating ?? 3;
    _roomTypes =
        widget.hotel != null ? List.from(widget.hotel!.availableRooms) : [];
    _imagePath = widget.hotel?.imagePath;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  void _addOrEditRoomType({RoomType? existingRoom, int? index}) {
    final nameController = TextEditingController(
      text: existingRoom?.name ?? '',
    );
    final priceController = TextEditingController(
      text: existingRoom?.pricePerNight.toString() ?? '',
    );
    final capacityController = TextEditingController(
      text: existingRoom?.capacity.toString() ?? '',
    );
    DateTime? startDate = existingRoom?.priceStartDate;
    DateTime? endDate = existingRoom?.priceEndDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(
                      existingRoom == null
                          ? 'إضافة نوع غرفة'
                          : 'تعديل نوع غرفة',
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'نوع الغرفة (مثال: سينجل)',
                            ),
                          ),
                          TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'السعر في الليلة',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          TextField(
                            controller: capacityController,
                            decoration: const InputDecoration(
                              labelText: 'عدد الأفراد',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'فترة صلاحية السعر (اختياري)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ListTile(
                            title: Text(
                              startDate == null
                                  ? 'تاريخ البدء'
                                  : 'من: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setDialogState(() => startDate = date);
                              }
                            },
                          ),
                          ListTile(
                            title: Text(
                              endDate == null
                                  ? 'تاريخ الانتهاء'
                                  : 'إلى: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    endDate ?? (startDate ?? DateTime.now()),
                                firstDate: startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setDialogState(() => endDate = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              priceController.text.isNotEmpty) {
                            final newRoom = RoomType(
                              id: existingRoom?.id ?? const Uuid().v4(),
                              name: nameController.text,
                              pricePerNight: double.parse(priceController.text),
                              capacity: int.parse(
                                capacityController.text.isEmpty
                                    ? '1'
                                    : capacityController.text,
                              ),
                              priceStartDate: startDate,
                              priceEndDate: endDate,
                            );
                            setState(() {
                              if (index != null) {
                                _roomTypes[index] = newRoom;
                              } else {
                                _roomTypes.add(newRoom);
                              }
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text(existingRoom == null ? 'إضافة' : 'تعديل'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _saveHotel() {
    if (_formKey.currentState!.validate() && _roomTypes.isNotEmpty) {
      final hotel = Hotel(
        id: widget.hotel?.id ?? const Uuid().v4(),
        name: _nameController.text,
        location: _locationController.text,
        starRating: _starRating,
        availableRooms: _roomTypes,
        imagePath: _imagePath,
        totalCapacity: int.parse(_capacityController.text),
        currentBookings: widget.hotel?.currentBookings ?? 0,
      );

      final provider = Provider.of<HotelProvider>(context, listen: false);
      if (widget.hotel == null) {
        provider.addHotel(hotel);
      } else {
        provider.updateHotel(hotel);
      }
      Navigator.pop(context);
    } else if (_roomTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة نوع غرفة واحد على الأقل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.hotel == null ? 'إضافة فندق جديد' : 'تعديل بيانات الفندق',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الفندق
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image:
                              _imagePath != null
                                  ? DecorationImage(
                                    image: FileImage(File(_imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            _imagePath == null
                                ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'اضغط لإضافة صورة الفندق',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفندق',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'الموقع (مدينة/دولة)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'إجمالي الغرف المتاحة',
                      hintText: 'مثال: 50',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      if (int.tryParse(v) == null) return 'يجب إدخال رقم صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تصنيف الفندق (نجوم)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _starRating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_starRating نجوم',
                    onChanged: (v) => setState(() => _starRating = v.round()),
                  ),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أنواع الغرف والأسعار',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addOrEditRoomType(),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة سعر'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _roomTypes.length,
                    itemBuilder: (context, index) {
                      final room = _roomTypes[index];
                      final currency =
                          Provider.of<SystemSettingsProvider>(
                            context,
                            listen: false,
                          ).currencySymbol;
                      return Card(
                        child: ListTile(
                          title: Text(
                            room.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السعر: $currency${room.pricePerNight} - الأفراد: ${room.capacity}',
                              ),
                              if (room.priceStartDate != null)
                                Text(
                                  'الفترة: ${DateFormat('yyyy-MM-dd').format(room.priceStartDate!)} إلى ${room.priceEndDate != null ? DateFormat('yyyy-MM-dd').format(room.priceEndDate!) : "مفتوح"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _addOrEditRoomType(
                                      existingRoom: room,
                                      index: index,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _roomTypes.removeAt(index),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveHotel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5BB8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.hotel == null ? 'حفظ الفندق' : 'تحديث البيانات',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
