import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'package:intl/intl.dart';
import '../providers/navigation_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/message_provider.dart';
import '../utils/backup_service.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';
import 'home_screen.dart';
import 'hotel_management_screen.dart';
import 'bookings_list_screen.dart';
import 'reports_screen.dart';
import 'new_booking_screen.dart';
import 'settings_screen.dart';
import 'extra_services_screen.dart';
import 'vault_screen.dart';
import 'remaining_payments_screen.dart';
import 'customers_screen.dart';
import 'activity_log_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _backupServiceStarted = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final user = authProvider.currentUser;

    if (!_backupServiceStarted) {
      BackupService().start(settingsProvider);
      _backupServiceStarted = true;
    }

    final List<Widget> screens = [
      const HomeScreenContent(),
      const HotelManagementScreen(),
      const BookingsListScreen(),
      const ReportsScreen(),
      const NewBookingScreen(),
      const ExtraServicesScreen(),
      const VaultScreen(),
      const RemainingPaymentsScreen(),
      const CustomersScreen(),
      const ActivityLogScreen(),
      const SettingsScreen(),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (settingsProvider.logoPath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(settingsProvider.logoPath!),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                settingsProvider.companyName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => _showImageSourceDialog(context, authProvider),
              child: CircleAvatar(
                backgroundImage:
                    user?.imagePath != null
                        ? FileImage(File(user!.imagePath!))
                        : const NetworkImage('https://via.placeholder.com/150')
                            as ImageProvider,
                radius: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(user?.name ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () => _showNotificationsPanel(context),
                    ),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${notificationProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.email_outlined),
                      onPressed: () => _showMessagesPanel(context),
                    ),
                    if (messageProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${messageProvider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: () {
                BackupService().stop();
                authProvider.logout();
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              color: const Color(0xFF1E5BB8),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSidebarItem(
                            0,
                            Icons.dashboard_outlined,
                            'لوحة التحكم',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            1,
                            Icons.hotel_outlined,
                            'الفنادق',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            2,
                            Icons.book_online_outlined,
                            'الحجوزات',
                            navProvider,
                          ),
                          if (authProvider.isAdmin)
                            _buildSidebarItem(
                              3,
                              Icons.bar_chart_outlined,
                              'التقارير',
                              navProvider,
                            ),
                          _buildSidebarItem(
                            4,
                            Icons.add_box_outlined,
                            'حجز جديد',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            5,
                            Icons.star_border_outlined,
                            'إضافات اختيارية',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            6,
                            Icons.account_balance_wallet_outlined,
                            'الخزنة',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            7,
                            Icons.money_off_outlined,
                            'متبقي الدفع',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            8,
                            Icons.people_outline,
                            'العملاء',
                            navProvider,
                          ),
                          _buildSidebarItem(
                            9,
                            Icons.history_outlined,
                            'سجل النشاط',
                            navProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSidebarItem(
                    10,
                    Icons.settings_outlined,
                    'الإعدادات',
                    navProvider,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: screens[navProvider.selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تغيير الصورة الشخصية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('كاميرا'),
                  onTap: () {
                    authProvider.pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('المعرض'),
                  onTap: () {
                    authProvider.pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showMessagesPanel(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 450,
                height: 600,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صندوق الوارد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () =>
                                    context
                                        .read<MessageProvider>()
                                        .markAllAsRead(),
                            child: const Text('تحديد الكل كمقروء'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Consumer<MessageProvider>(
                        builder: (context, provider, child) {
                          if (provider.messages.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mail_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'لا توجد رسائل حالياً',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: provider.messages.length,
                            itemBuilder: (context, index) {
                              final message = provider.messages[index];
                              return _buildMessageTile(
                                context,
                                message,
                                provider,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    MessageModel message,
    MessageProvider provider,
  ) {
    return Container(
      color: message.isRead ? null : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            message.sender[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message.sender,
                style: TextStyle(
                  fontWeight:
                      message.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.subject,
              style: TextStyle(
                fontWeight:
                    message.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.body,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () {
          provider.markAsRead(message.id);
          _showMessageDetail(context, message);
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () => provider.deleteMessage(message.id),
        ),
      ),
    );
  }

  void _showMessageDetail(BuildContext context, MessageModel message) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: Text(message.subject),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'من: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${message.sender} (${message.senderEmail ?? ""})'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(message.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 24),
                  Text(message.body),
                ],
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

  void _showNotificationsPanel(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإشعارات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () =>
                                    context
                                        .read<NotificationProvider>()
                                        .markAllAsRead(),
                            child: const Text('تحديد الكل كمقروء'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Consumer<NotificationProvider>(
                        builder: (context, provider, child) {
                          if (provider.notifications.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'لا توجد إشعارات حالياً',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: provider.notifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  provider.notifications[index];
                              return _buildNotificationTile(
                                context,
                                notification,
                                provider,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    IconData icon = Icons.notifications;
    Color color = Colors.blue;

    switch (notification.type) {
      case NotificationType.checkoutSoon:
        icon = Icons.exit_to_app;
        color = Colors.orange;
        break;
      case NotificationType.remainingPayment:
        icon = Icons.money_off;
        color = Colors.red;
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
    }

    return Container(
      color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
          provider.markAsRead(notification.id);
          // هنا يمكن إضافة التنقل لمكان الحدث
          if (notification.type == NotificationType.remainingPayment) {
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).setIndex(7); // صفحة متبقي الدفع
            Navigator.pop(context);
          } else if (notification.type == NotificationType.checkoutSoon) {
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).setIndex(2); // صفحة الحجوزات
            Navigator.pop(context);
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => provider.deleteNotification(notification.id),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${timestamp.year}-${timestamp.month}-${timestamp.day}';
    }
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    String label,
    NavigationProvider nav,
  ) {
    bool isSelected = nav.selectedIndex == index;
    return InkWell(
      onTap: () => nav.setIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border:
              isSelected
                  ? const Border(
                    right: BorderSide(color: Colors.white, width: 4),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
