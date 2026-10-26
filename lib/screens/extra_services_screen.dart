import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/extra_service.dart';
import '../providers/navigation_provider.dart';
import '../providers/extra_services_provider.dart';

class ExtraServicesScreen extends StatelessWidget {
  const ExtraServicesScreen({super.key});

  void _showAddEditServiceDialog(
    BuildContext context, {
    ExtraService? service,
  }) {
    final nameController = TextEditingController(text: service?.name);
    final priceController = TextEditingController(
      text: service?.price.toString(),
    );
    ServiceType selectedType = service?.type ?? ServiceType.other;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(
                      service == null ? 'إضافة خدمة جديدة' : 'تعديل الخدمة',
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم الخدمة',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'السعر'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ServiceType>(
                          value: selectedType,
                          items:
                              ServiceType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type == ServiceType.transfer
                                        ? 'انتقال'
                                        : type == ServiceType.meal
                                        ? 'وجبة'
                                        : 'أخرى',
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              (v) => setDialogState(() => selectedType = v!),
                          decoration: const InputDecoration(
                            labelText: 'نوع الخدمة',
                          ),
                        ),
                      ],
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
                            final newService = ExtraService(
                              id: service?.id ?? const Uuid().v4(),
                              name: nameController.text,
                              price:
                                  double.tryParse(priceController.text) ?? 0.0,
                              type: selectedType,
                            );

                            final provider = Provider.of<ExtraServicesProvider>(
                              context,
                              listen: false,
                            );
                            if (service == null) {
                              provider.addService(newService);
                            } else {
                              provider.updateService(newService);
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final extraProvider = Provider.of<ExtraServicesProvider>(context);
    final commonServices = extraProvider.services;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEditServiceDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('إضافة خدمة'),
          backgroundColor: const Color(0xFF1E5BB8),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إضافات اختيارية',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E5BB8),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => extraProvider.loadServices(),
                    color: const Color(0xFF1E5BB8),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'الخدمات المتاحة حالياً',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (commonServices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Text('لا توجد خدمات إضافية متاحة حالياً'),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      commonServices.map((service) {
                        return InkWell(
                          onTap:
                              () => _showAddEditServiceDialog(
                                context,
                                service: service,
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  service.type == ServiceType.transfer
                                      ? Icons.directions_bus_outlined
                                      : service.type == ServiceType.meal
                                      ? Icons.restaurant_outlined
                                      : Icons.star_border_outlined,
                                  color: const Color(0xFF1E5BB8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${service.name} (${service.price}\$)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('حذف الخدمة'),
                                            content: const Text(
                                              'هل أنت متأكد من حذف هذه الخدمة؟',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('إلغاء'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  extraProvider.deleteService(
                                                    service.id,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
                                                  'حذف',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'يمكنك ربط هذه الخدمات مع الحجوزات الجديدة مباشرة',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => navProvider.setIndex(1),
                      icon: const Icon(Icons.add),
                      label: const Text('بدء حجز جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1E5BB8,
                        ).withOpacity(0.05),
                        foregroundColor: const Color(0xFF1E5BB8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
