import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/hotel.dart';
import '../models/room_type.dart';
import '../models/extra_service.dart';
import '../providers/hotel_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/vault_transaction.dart';
import '../utils/pdf_helper.dart';
import '../providers/extra_services_provider.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _peopleController = TextEditingController(text: '1');
  final _advancePaymentController = TextEditingController(text: '0');

  Hotel? _selectedHotel;
  RoomType? _selectedRoomType;
  DateTimeRange? _dateRange;
  final List<ExtraService> _selectedServices = [];

  void _saveBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHotel == null) {
        _showError('الرجاء اختيار الفندق');
        return;
      }

      // التحقق من السعة المتاحة
      if (_selectedHotel!.totalCapacity > 0 &&
          _selectedHotel!.currentBookings >= _selectedHotel!.totalCapacity) {
        _showError(
          'عذراً، هذا الفندق مكتمل العدد حالياً (${_selectedHotel!.currentBookings}/${_selectedHotel!.totalCapacity})',
        );
        return;
      }

      if (_selectedRoomType == null) {
        _showError('الرجاء اختيار نوع الغرفة');
        return;
      }
      if (_dateRange == null) {
        _showError('الرجاء اختيار تاريخ الإقامة');
        return;
      }

      final nights = _dateRange!.duration.inDays;
      if (nights <= 0) {
        _showError('يجب أن يكون عدد الليالي ليلة واحدة على الأقل');
        return;
      }

      final people = int.tryParse(_peopleController.text) ?? 1;
      if (people <= 0) {
        _showError('يجب أن يكون عدد الأفراد شخصاً واحداً على الأقل');
        return;
      }

      final advancePayment =
          double.tryParse(_advancePaymentController.text) ?? 0.0;

      final booking = Booking(
        id: const Uuid().v4(),
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        customerEmail: _customerEmailController.text,
        hotel: _selectedHotel!,
        roomType: _selectedRoomType!,
        numberOfNights: nights,
        checkInDate: _dateRange!.start,
        checkOutDate: _dateRange!.end,
        extraServices: List.from(_selectedServices),
        numberOfPeople: people,
        advancePayment: advancePayment,
      );

      try {
        await Provider.of<BookingProvider>(
          context,
          listen: false,
        ).addBooking(booking);

        // إضافة العملية للخزنة تلقائياً (المقدم فقط)
        if (mounted && advancePayment > 0) {
          await Provider.of<VaultProvider>(
            context,
            listen: false,
          ).addTransaction(
            'مقدم حجز: ${booking.customerName}',
            advancePayment,
            TransactionType.deposit,
            description: 'مقدم حجز فندق ${booking.hotel.name}',
          );
        }

        _showSuccess(
          advancePayment > 0
              ? 'تم حفظ الحجز بنجاح وإيداع المقدم في الخزنة'
              : 'تم حفظ الحجز بنجاح',
        );

        // عرض خيار الطباعة مباشرة
        if (mounted) {
          final settings = Provider.of<SystemSettingsProvider>(
            context,
            listen: false,
          );
          await PdfHelper.printBookingReport(
            booking,
            settings.companyName,
            settings.logoPath,
            settings.currencySymbol,
          );
        }

        // الانتقال لشاشة الحجوزات بعد النجاح
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Provider.of<NavigationProvider>(context, listen: false).setIndex(2);
          }
        });

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // إذا كانت الشاشة معروضة داخل MainLayout (Sidebar)
          // نقوم بتصفير الفورم للسماح بحجز جديد
          _resetForm();
        }
      } catch (e) {
        _showError('حدث خطأ أثناء حفظ الحجز: $e');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _customerNameController.clear();
      _peopleController.text = '1';
      _selectedHotel = null;
      _selectedRoomType = null;
      _dateRange = null;
      _selectedServices.clear();
    });
    _formKey.currentState?.reset();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotels = Provider.of<HotelProvider>(context).hotels;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_box, color: Color(0xFF1E5BB8), size: 28),
                      SizedBox(width: 8),
                      Text(
                        'إضافة حجز جديد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E5BB8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        _resetForm();
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 40),

              // Form Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اسم العميل',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            hintText: 'مثال: محمد علي',
                            prefixIcon: Icon(Icons.person_outline),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'رقم الهاتف',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerPhoneController,
                          decoration: const InputDecoration(
                            hintText: 'مثال: 01000000000',
                            prefixIcon: Icon(Icons.phone_outlined),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'البريد الإلكتروني',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerEmailController,
                          decoration: const InputDecoration(
                            hintText: 'example@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'نوع الغرفة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildRoomTypeSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Left Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الفندق',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Hotel>(
                          decoration: const InputDecoration(
                            hintText: 'اختر الفندق',
                            prefixIcon: Icon(Icons.hotel_outlined),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          value: _selectedHotel,
                          items:
                              hotels
                                  .map(
                                    (h) => DropdownMenuItem(
                                      value: h,
                                      child: Text(h.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null &&
                                v.totalCapacity > 0 &&
                                v.currentBookings >= v.totalCapacity) {
                              _showError(
                                'هذا الفندق مكتمل العدد حالياً (${v.currentBookings}/${v.totalCapacity})',
                              );
                            }
                            setState(() {
                              _selectedHotel = v;
                              _selectedRoomType = null;
                            });
                          },
                          validator: (v) => v == null ? 'مطلوب' : null,
                        ),
                        if (_selectedHotel != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedHotel!.starRating} نجوم',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.meeting_room_outlined,
                                color:
                                    _selectedHotel!.currentBookings >=
                                                _selectedHotel!.totalCapacity &&
                                            _selectedHotel!.totalCapacity > 0
                                        ? Colors.red
                                        : Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedHotel!.currentBookings} / ${_selectedHotel!.totalCapacity} غرف مشغولة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedHotel!.currentBookings >=
                                                  _selectedHotel!
                                                      .totalCapacity &&
                                              _selectedHotel!.totalCapacity > 0
                                          ? Colors.red
                                          : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              Text(
                                _selectedHotel!.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'تاريخ الإقامة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _dateRange = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _dateRange == null
                                      ? 'اختر التواريخ'
                                      : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)} (${_dateRange!.duration.inDays} ليالي)',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'عدد الأفراد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _peopleController,
                          decoration: const InputDecoration(
                            hintText: 'مثال: 2',
                            prefixIcon: Icon(Icons.people_outline),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'مطلوب';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'أدخل رقم صحيح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'المقدم (إن وجد)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _advancePaymentController,
                          decoration: const InputDecoration(
                            hintText: 'مثال: 500',
                            prefixIcon: Icon(Icons.money_off_outlined),
                            fillColor: Color(0xFFF9FAFB),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'تفاصيل الأسعار',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prices Table
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF9FAFB),
                        ),
                        columns: const [
                          DataColumn(label: Text('نوع الغرفة')),
                          DataColumn(label: Text('السعر في الليلة')),
                        ],
                        rows:
                            _selectedHotel?.availableRooms
                                .map(
                                  (r) => DataRow(
                                    selected: _selectedRoomType?.id == r.id,
                                    cells: [
                                      DataCell(Text(r.name)),
                                      DataCell(
                                        Text(
                                          '\$ ${r.pricePerNight}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onSelectChanged: (v) {
                                      if (v == true) {
                                        setState(() => _selectedRoomType = r);
                                      }
                                    },
                                  ),
                                )
                                .toList() ??
                            [
                              const DataRow(
                                cells: [
                                  DataCell(Text('يرجى اختيار فندق')),
                                  DataCell(Text('-')),
                                ],
                              ),
                            ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Calculation Summary
                  Expanded(flex: 2, child: _buildCalculationSummaryUI()),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'إضافات اختيارية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOptionalExtrasUI(),

              const SizedBox(height: 40),
              // Bottom Bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    if (_selectedHotel == null) {
      return const Text(
        'يرجى اختيار فندق أولاً',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 8,
      children:
          _selectedHotel!.availableRooms.map((r) {
            bool isSelected = _selectedRoomType?.id == r.id;
            return ChoiceChip(
              label: Text(r.name),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedRoomType = r),
              selectedColor: const Color(0xFF2ECC71),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCalculationSummaryUI() {
    if (_selectedRoomType == null || _dateRange == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9F3),
          border: Border.all(color: const Color(0xFFFDE6D2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'يرجى اختيار الغرفة والتواريخ لعرض الملخص',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final nights = _dateRange?.duration.inDays ?? 0;
    final people = int.tryParse(_peopleController.text) ?? 1;
    final roomPrice = _selectedRoomType?.pricePerNight ?? 0;
    final roomTotal = roomPrice * nights * people;
    final servicesTotal = _selectedServices.fold(
      0.0,
      (sum, s) => sum + s.price,
    );
    final totalAmount = roomTotal + servicesTotal;

    final advance = double.tryParse(_advancePaymentController.text) ?? 0.0;
    final remaining = totalAmount - advance;

    final perPerson = people > 0 ? totalAmount / people : totalAmount;

    final isTriple =
        _selectedRoomType?.name.toLowerCase().contains('تريبل') == true ||
        _selectedRoomType?.name.toLowerCase().contains('triple') == true;

    final settingsProvider = Provider.of<SystemSettingsProvider>(
      context,
      listen: false,
    );
    final currency = settingsProvider.currencySymbol;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9F3),
        border: Border.all(color: const Color(0xFFFDE6D2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _summaryRowUI(
            'سعر الغرفة ($nights ليالي × $people أفراد)',
            '$currency${roomTotal.toStringAsFixed(2)}',
          ),
          _summaryRowUI(
            'إجمالي الخدمات',
            '$currency${servicesTotal.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _summaryRowUI(
            'الإجمالي الكلي',
            '$currency${totalAmount.toStringAsFixed(2)}',
            isBold: true,
          ),
          _summaryRowUI(
            'المقدم المدفوع',
            '$currency${advance.toStringAsFixed(2)}',
            color: Colors.green,
          ),
          _summaryRowUI(
            'المتبقي',
            '$currency${remaining.toStringAsFixed(2)}',
            isBold: true,
            color: Colors.red,
          ),
          const Divider(height: 24),
          _summaryRowUI(
            'السعر للفرد',
            '$currency${perPerson.toStringAsFixed(2)}',
            color: const Color(0xFF1E5BB8),
            isBold: true,
          ),
          if (people >= 2 && !isTriple)
            _summaryRowUI(
              'السعر للفردين',
              '$currency${(perPerson * 2).toStringAsFixed(2)}',
              color: const Color(0xFF1E5BB8),
              isBold: true,
            ),
        ],
      ),
    );
  }

  Widget _summaryRowUI(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              color: color,
              fontSize: isBold ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalExtrasUI() {
    final currency =
        Provider.of<SystemSettingsProvider>(
          context,
          listen: false,
        ).currencySymbol;
    final extraProvider = Provider.of<ExtraServicesProvider>(context);
    final commonServices = extraProvider.services;

    if (commonServices.isEmpty) {
      return const Text(
        'لا توجد خدمات إضافية متاحة حالياً',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children:
          commonServices.map((service) {
            final isSelected = _selectedServices.any((s) => s.id == service.id);
            return FilterChip(
              label: Text('${service.name} ($currency${service.price})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.removeWhere((s) => s.id == service.id);
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1E5BB8).withOpacity(0.1),
              checkmarkColor: const Color(0xFF1E5BB8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      isSelected
                          ? const Color(0xFF1E5BB8)
                          : const Color(0xFFE0E0E0),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBottomBar() {
    final settingsProvider = Provider.of<SystemSettingsProvider>(
      context,
      listen: false,
    );
    final currency = settingsProvider.currencySymbol;
    final taxPercentage = settingsProvider.taxPercentage;

    final nights = _dateRange?.duration.inDays ?? 0;
    final people = int.tryParse(_peopleController.text) ?? 1;
    final roomTotal = (_selectedRoomType?.pricePerNight ?? 0) * nights * people;
    final servicesTotal = _selectedServices.fold(
      0.0,
      (sum, s) => sum + s.price,
    );
    final totalAmount = roomTotal + servicesTotal;

    final perPerson = people > 0 ? totalAmount / people : totalAmount;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$currency${perPerson.toStringAsFixed(2)} : سعر الفرد',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5BB8),
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'تأكيد الحجز',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$currency${totalAmount.toStringAsFixed(2)} : الإجمالي الكلي',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
