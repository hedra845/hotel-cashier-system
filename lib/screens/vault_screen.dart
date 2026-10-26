import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vault_provider.dart';
import '../models/vault_transaction.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../utils/export_helper.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = Provider.of<VaultProvider>(context);
    final settingsProvider = Provider.of<SystemSettingsProvider>(context);
    final transactions = vaultProvider.transactions;
    final currency = settingsProvider.currencySymbol;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الخزنة والمالية',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E5BB8),
                    ),
                  ),
                  if (transactions.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.table_view,
                            color: Colors.green,
                          ),
                          tooltip: 'تصدير Excel',
                          onPressed:
                              () => ExportHelper.exportVaultExcel(
                                transactions,
                                currency,
                                vaultProvider.totalBalance,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.description,
                            color: Colors.blue,
                          ),
                          tooltip: 'تصدير Word',
                          onPressed: () {
                            final List<String> headers = [
                              'التاريخ',
                              'البيان',
                              'النوع',
                              'المبلغ',
                            ];
                            final List<List<String>> data =
                                transactions
                                    .map(
                                      (tx) => [
                                        DateFormat(
                                          'yyyy-MM-dd HH:mm',
                                        ).format(tx.date),
                                        tx.title,
                                        tx.type == TransactionType.deposit
                                            ? 'إيداع'
                                            : 'سحب',
                                        '$currency${tx.amount}',
                                      ],
                                    )
                                    .toList();
                            ExportHelper.exportToWord(
                              'تقرير الخزنة',
                              headers,
                              data,
                              'vault_report',
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Balance Card
              _buildBalanceCard(vaultProvider.totalBalance, currency),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    context,
                    'إيداع أموال',
                    Icons.add_circle_outline,
                    Colors.green,
                    () => _showTransactionDialog(
                      context,
                      TransactionType.deposit,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    context,
                    'سحب أموال',
                    Icons.remove_circle_outline,
                    Colors.red,
                    () => _showTransactionDialog(
                      context,
                      TransactionType.withdrawal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              const Text(
                'آخر الحركات المالية',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Transactions List
              Expanded(
                child:
                    transactions.isEmpty
                        ? _buildEmptyState()
                        : Container(
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
                            itemCount: transactions.length,
                            separatorBuilder:
                                (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return _buildTransactionItem(tx, currency);
                            },
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, String currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E5BB8), Color(0xFF4A90E2)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5BB8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'إجمالي الرصيد الحالي',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$currency${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(VaultTransaction tx, String currency) {
    final isDeposit = tx.type == TransactionType.deposit;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isDeposit ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        DateFormat('yyyy-MM-dd hh:mm a').format(tx.date),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Text(
        '${isDeposit ? "+" : "-"}$currency${tx.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: isDeposit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, TransactionType type) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                type == TransactionType.deposit ? 'إيداع جديد' : 'سحب جديد',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'البيان (مثلاً: دفعة حجز هيدرا)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                    keyboardType: TextInputType.number,
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
                    final amount = double.tryParse(amountController.text);
                    if (titleController.text.isNotEmpty && amount != null) {
                      Provider.of<VaultProvider>(
                        context,
                        listen: false,
                      ).addTransaction(titleController.text, amount, type);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا توجد حركات مالية مسجلة بعد',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
