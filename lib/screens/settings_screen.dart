import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/hotel_provider.dart';
import '../providers/booking_provider.dart';
import '../utils/database_helper.dart';

import '../providers/settings_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  final _companyNameController = TextEditingController();
  final _currencyController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SystemSettingsProvider>(
        context,
        listen: false,
      );
      _companyNameController.text = provider.companyName;
      _currencyController.text = provider.currencySymbol;
      _emailController.text = provider.email;
      _taxController.text = provider.taxPercentage.toString();
    });
  }

  Future<void> _updateCompanySettings() async {
    final settingsProvider = Provider.of<SystemSettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.updateSettings(
      name: _companyNameController.text,
      logo: settingsProvider.logoPath,
      currency: _currencyController.text,
      email: _emailController.text,
      taxPercentage: double.tryParse(_taxController.text) ?? 0.0,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث إعدادات النظام بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final settingsProvider = Provider.of<SystemSettingsProvider>(
        context,
        listen: false,
      );
      await settingsProvider.updateSettings(
        name: _companyNameController.text,
        logo: image.path,
      );
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final dbHelper = DatabaseHelper();
      final data = await dbHelper.exportDatabase();
      final jsonString = jsonEncode(data);

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
        fileName:
            'hotel_backup_${DateTime.now().year.toString().padLeft(4, '0')}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().minute.toString().padLeft(2, '0')}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.json')) {
          outputFile += '.json';
        }
        final file = File(outputFile);
        await file.writeAsString(jsonString);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تصدير النسخة الاحتياطية بنجاح إلى: $outputFile',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString);

        final dbHelper = DatabaseHelper();
        await dbHelper.importDatabase(data);

        // تحديث البيانات في الـ Providers
        if (context.mounted) {
          await Provider.of<HotelProvider>(context, listen: false).loadHotels();
          await Provider.of<BookingProvider>(
            context,
            listen: false,
          ).loadBookings();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم استعادة البيانات بنجاح من الملف المختار'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الاستيراد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _pickBackupDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'اختر مجلد حفظ النسخ الاحتياطية التلقائية',
    );

    if (selectedDirectory != null) {
      final settingsProvider = Provider.of<SystemSettingsProvider>(
        context,
        listen: false,
      );
      await settingsProvider.updateSettings(
        name: _companyNameController.text,
        backupDir: selectedDirectory,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('الإعدادات والنظام'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // قسم هوية الشركة
              _buildSectionHeader(
                'هوية الشركة واللوجو',
                Icons.business_outlined,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                children: [
                  _buildSettingTile(
                    title: 'اسم الشركة',
                    subtitle: 'الاسم الذي سيظهر في أعلى القائمة الجانبية',
                    icon: Icons.edit_note_outlined,
                    trailing: SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                hintText: 'ادخل اسم الشركة',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _updateCompanySettings,
                            child: const Text('حفظ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'رمز العملة',
                    subtitle:
                        'الرمز الذي سيظهر بجانب المبالغ المالية في النظام',
                    icon: Icons.monetization_on_outlined,
                    trailing: SizedBox(
                      width: 250,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _currencyController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '\$',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _updateCompanySettings,
                            child: const Text('حفظ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'البريد الإلكتروني',
                    subtitle: 'البريد الذي سيتم استخدامه لإرسال التقارير',
                    icon: Icons.email_outlined,
                    trailing: SizedBox(
                      width: 350,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'example@email.com',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _updateCompanySettings,
                            child: const Text('حفظ'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Consumer<SystemSettingsProvider>(
                    builder:
                        (context, settings, child) => _buildSettingTile(
                          title: 'لوجو الشركة',
                          subtitle: 'الصورة التي ستظهر بجانب اسم الشركة',
                          icon: Icons.image_outlined,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (settings.logoPath != null &&
                                  settings.logoPath!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(settings.logoPath!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              ElevatedButton(
                                onPressed: _pickLogo,
                                child: Text(
                                  settings.logoPath == null ||
                                          settings.logoPath!.isEmpty
                                      ? 'اختيار لوجو'
                                      : 'تغيير اللوجو',
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // قسم النسخ الاحتياطي
              _buildSectionHeader(
                'النسخ الاحتياطي والأمان',
                Icons.backup_outlined,
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(
                children: [
                  Consumer<SystemSettingsProvider>(
                    builder:
                        (context, settings, child) => Column(
                          children: [
                            _buildSettingTile(
                              title: 'النسخ الاحتياطي التلقائي',
                              subtitle:
                                  'تصدير نسخة احتياطية تلقائياً كل يوم الساعة 12 صباحاً',
                              icon: Icons.auto_mode_outlined,
                              trailing: Switch(
                                value: settings.autoBackupEnabled,
                                onChanged: (v) {
                                  settings.updateSettings(
                                    name: _companyNameController.text,
                                    autoBackup: v,
                                  );
                                },
                              ),
                            ),
                            if (settings.autoBackupEnabled) ...[
                              const Divider(),
                              _buildSettingTile(
                                title: 'مجلد النسخ التلقائي',
                                subtitle:
                                    settings.backupDirectory ??
                                    'لم يتم اختيار مجلد بعد',
                                icon: Icons.folder_open_outlined,
                                trailing: ElevatedButton(
                                  onPressed: _pickBackupDirectory,
                                  child: const Text('اختيار المجلد'),
                                ),
                              ),
                            ],
                          ],
                        ),
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'تصدير نسخة احتياطية',
                    subtitle: 'حفظ كافة البيانات (فنادق، حجوزات) في ملف خارجي',
                    icon: Icons.cloud_upload_outlined,
                    trailing:
                        _isExporting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: _exportData,
                              child: const Text('تصدير الآن'),
                            ),
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'استعادة نسخة احتياطية',
                    subtitle:
                        'استبدال البيانات الحالية ببيانات من ملف محفوظ مسبقاً',
                    icon: Icons.cloud_download_outlined,
                    trailing:
                        _isImporting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: _importData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('استعادة الآن'),
                            ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // قسم الصلاحيات والمستخدمين
              if (isAdmin) ...[
                _buildSectionHeader(
                  'إدارة الصلاحيات والمستخدمين',
                  Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 16),
                _buildSettingsCard(
                  children: [
                    // عرض المستخدمين الحاليين
                    Consumer<AuthProvider>(
                      builder:
                          (context, auth, child) => Column(
                            children:
                                auth.allUsers
                                    .map(
                                      (user) => Column(
                                        children: [
                                          _buildSettingTile(
                                            title: user.name,
                                            subtitle:
                                                '${user.role == UserRole.admin ? "مدير" : "موظف"} - ${user.email}',
                                            icon: Icons.person_outline,
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      () => _showAddUserDialog(
                                                        context,
                                                        existingUser: user,
                                                      ),
                                                ),
                                                if (user.id !=
                                                    auth.currentUser?.id)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed:
                                                        () =>
                                                            _showDeleteUserDialog(
                                                              context,
                                                              auth,
                                                              user,
                                                            ),
                                                  ),
                                                Switch(
                                                  value:
                                                      user.role ==
                                                      UserRole.admin,
                                                  onChanged: (v) {
                                                    auth.updateUserRole(
                                                      user.id,
                                                      v
                                                          ? UserRole.admin
                                                          : UserRole.employee,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (user != auth.allUsers.last)
                                            const Divider(),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          ),
                    ),
                    const Divider(),
                    // زر إضافة مستخدم جديد
                    _buildSettingTile(
                      title: 'إضافة مستخدم جديد',
                      subtitle: 'إنشاء حساب جديد لموظف أو مدير',
                      icon: Icons.person_add_outlined,
                      onTap: () => _showAddUserDialog(context),
                      trailing: const Icon(Icons.add, color: Colors.blue),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // قسم عام
              _buildSectionHeader('إعدادات عامة', Icons.settings_outlined),
              const SizedBox(height: 16),
              _buildSettingsCard(
                children: [
                  _buildSettingTile(
                    title: 'لغة النظام',
                    subtitle: 'العربية (اللغة الافتراضية)',
                    icon: Icons.language_outlined,
                    trailing: const Text(
                      'تغيير',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'المطور',
                    subtitle: 'BY ENG/Hedra Naguib',
                    icon: Icons.code_outlined,
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'رقم الهاتف للمطور',
                    subtitle: '01551407492',
                    icon: Icons.phone_android_outlined,
                  ),
                  const Divider(),
                  _buildSettingTile(
                    title: 'تسجيل الخروج',
                    subtitle: 'الخروج من النظام والعودة لشاشة الدخول',
                    icon: Icons.logout,
                    onTap: () => authProvider.logout(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E5BB8), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E5BB8),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1E5BB8)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showAddUserDialog(BuildContext context, {AppUser? existingUser}) {
    final nameController = TextEditingController(text: existingUser?.name);
    final passwordController = TextEditingController(
      text: existingUser?.password,
    );
    UserRole selectedRole = existingUser?.role ?? UserRole.employee;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(
                      existingUser == null
                          ? 'إضافة مستخدم جديد'
                          : 'تعديل بيانات المستخدم',
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                          ),
                        ),
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserRole>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'الصلاحية',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.admin,
                              child: Text('مدير'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.employee,
                              child: Text('موظف'),
                            ),
                          ],
                          onChanged: (v) => setState(() => selectedRole = v!),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              passwordController.text.isNotEmpty) {
                            final auth = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (existingUser == null) {
                              await auth.addNewUser(
                                nameController.text,
                                passwordController.text,
                                selectedRole,
                              );
                            } else {
                              await auth.updateUserDetails(
                                existingUser.id,
                                name: nameController.text,
                                password: passwordController.text,
                                role: selectedRole,
                              );
                            }
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: Text(
                          existingUser == null ? 'إضافة' : 'حفظ التعديلات',
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showDeleteUserDialog(
    BuildContext context,
    AuthProvider auth,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف المستخدم'),
              content: Text('هل أنت متأكد من حذف المستخدم ${user.name}؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    await auth.deleteUser(user.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
    );
  }
}
