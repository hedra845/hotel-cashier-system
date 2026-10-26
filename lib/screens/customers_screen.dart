import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../utils/export_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label بنجاح'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Booking customer) {
    final nameController = TextEditingController(text: customer.customerName);
    final phoneController = TextEditingController(
      text: customer.customerPhone ?? '',
    );
    final emailController = TextEditingController(
      text: customer.customerEmail ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تعديل بيانات العميل'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم العميل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await Provider.of<BookingProvider>(
                        context,
                        listen: false,
                      ).updateCustomerData(
                        oldName: customer.customerName,
                        newName: nameController.text.trim(),
                        newPhone: phoneController.text.trim(),
                        newEmail: emailController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث بيانات العميل بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final bookings = bookingProvider.bookings;

    // استخراج قائمة فريدة للعملاء مع الحرص على أخذ البيانات الأكثر اكتمالاً
    final Map<String, Booking> uniqueCustomers = {};
    for (var booking in bookings) {
      final key = booking.customerName.trim().toLowerCase();
      if (!uniqueCustomers.containsKey(key)) {
        uniqueCustomers[key] = booking;
      } else {
        // إذا وجدنا نسخة أخرى لنفس العميل، نفضل النسخة التي تحتوي على بيانات أكثر
        final existing = uniqueCustomers[key]!;
        int existingScore =
            (existing.customerPhone?.isNotEmpty == true ? 1 : 0) +
            (existing.customerEmail?.isNotEmpty == true ? 1 : 0);
        int currentScore =
            (booking.customerPhone?.isNotEmpty == true ? 1 : 0) +
            (booking.customerEmail?.isNotEmpty == true ? 1 : 0);

        if (currentScore > existingScore) {
          uniqueCustomers[key] = booking;
        }
      }
    }

    final customersList =
        uniqueCustomers.values.where((customer) {
          final query = _searchQuery.toLowerCase();
          final name = customer.customerName.toLowerCase();
          final phone = (customer.customerPhone ?? '').toLowerCase();
          final email = (customer.customerEmail ?? '').toLowerCase();
          return name.contains(query) ||
              phone.contains(query) ||
              email.contains(query);
        }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العملاء'),
          actions: [
            if (customersList.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.table_view, color: Colors.green),
                tooltip: 'تصدير Excel',
                onPressed: () {
                  final exportData =
                      customersList.map((c) {
                        return {
                          'name': c.customerName,
                          'phone': c.customerPhone,
                          'email': c.customerEmail,
                          'bookingCount':
                              bookings
                                  .where(
                                    (b) =>
                                        b.customerName.toLowerCase() ==
                                        c.customerName.toLowerCase(),
                                  )
                                  .length,
                        };
                      }).toList();
                  ExportHelper.exportCustomersExcel(exportData);
                },
              ),
              IconButton(
                icon: const Icon(Icons.description, color: Colors.blue),
                tooltip: 'تصدير Word',
                onPressed: () {
                  final List<String> headers = [
                    'العميل',
                    'رقم الهاتف',
                    'البريد الإلكتروني',
                  ];
                  final List<List<String>> data =
                      customersList
                          .map(
                            (c) => [
                              c.customerName,
                              c.customerPhone ?? '-',
                              c.customerEmail ?? '-',
                            ],
                          )
                          .toList();
                  ExportHelper.exportToWord(
                    'قائمة العملاء',
                    headers,
                    data,
                    'customers_list',
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
                  hintText: 'ابحث عن عميل باسمه، هاتفه، أو بريده...',
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
            customersList.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لا يوجد عملاء مسجلين بعد'
                            : 'لا توجد نتائج مطابقة لبحثك',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customersList.length,
                  itemBuilder: (context, index) {
                    final customer = customersList[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF1E5BB8,
                          ).withOpacity(0.1),
                          child: Text(
                            customer.customerName.isNotEmpty
                                ? customer.customerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF1E5BB8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            const Text(
                              'الاسم: ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              customer.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap:
                                  () => _copyToClipboard(
                                    context,
                                    customer.customerName,
                                    'الاسم',
                                  ),
                              child: const Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'الهاتف: ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  customer.customerPhone != null &&
                                          customer.customerPhone!.isNotEmpty
                                      ? customer.customerPhone!
                                      : 'غير مسجل',
                                  style: TextStyle(
                                    color:
                                        customer.customerPhone != null &&
                                                customer
                                                    .customerPhone!
                                                    .isNotEmpty
                                            ? Colors.black87
                                            : Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                if (customer.customerPhone != null &&
                                    customer.customerPhone!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap:
                                        () => _copyToClipboard(
                                          context,
                                          customer.customerPhone!,
                                          'رقم الهاتف',
                                        ),
                                    child: const Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'البريد: ',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  customer.customerEmail != null &&
                                          customer.customerEmail!.isNotEmpty
                                      ? customer.customerEmail!
                                      : 'غير مسجل',
                                  style: TextStyle(
                                    color:
                                        customer.customerEmail != null &&
                                                customer
                                                    .customerEmail!
                                                    .isNotEmpty
                                            ? Colors.blue[600]
                                            : Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                if (customer.customerEmail != null &&
                                    customer.customerEmail!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap:
                                        () => _copyToClipboard(
                                          context,
                                          customer.customerEmail!,
                                          'البريد الإلكتروني',
                                        ),
                                    child: const Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                                size: 20,
                              ),
                              tooltip: 'تعديل البيانات',
                              onPressed:
                                  () => _showEditCustomerDialog(
                                    context,
                                    customer,
                                  ),
                            ),
                            if (customer.customerPhone != null &&
                                customer.customerPhone!.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                onPressed:
                                    () => launchUrl(
                                      Uri.parse(
                                        'tel:${customer.customerPhone}',
                                      ),
                                    ),
                              ),
                            if (customer.customerEmail != null &&
                                customer.customerEmail!.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.email,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final url = Uri.parse(
                                    'mailto:${customer.customerEmail}',
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
                                        customer.customerEmail!,
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  void _showEmailFallbackDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تواصل مع العميل'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تعذر فتح تطبيق البريد تلقائياً. يمكنك نسخ البريد الإلكتروني أدناه:',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ البريد الإلكتروني')),
                    );
                  },
                  child: const Text('نسخ البريد'),
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
