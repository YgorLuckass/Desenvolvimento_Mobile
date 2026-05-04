// lib/views/dashboard/dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import '../dashboard/add_transaction_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final txVm = context.watch<TransactionViewModel>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final name = authVm.currentUser?.name.split(' ').first ?? 'Usuário';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Olá, $name 👋',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(txVm.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text('Saldo disponível',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                tooltip: 'Análise',
                onPressed: () =>
                    Navigator.pushNamed(context, '/analysis'),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Sair',
                onPressed: () {
                  context.read<AuthViewModel>().logout();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income / Expense Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Receitas',
                          value: currency.format(txVm.totalIncome),
                          icon: Icons.arrow_upward_rounded,
                          color: AppTheme.income,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Despesas',
                          value: currency.format(txVm.totalExpense),
                          icon: Icons.arrow_downward_rounded,
                          color: AppTheme.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transações Recentes',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/analysis'),
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Transaction List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final tx = txVm.recentTransactions[i];
                return _TransactionTile(transaction: tx);
              },
              childCount: txVm.recentTransactions.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddTransactionDialog(),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final color = transaction.isIncome ? AppTheme.income : AppTheme.expense;
    final sign = transaction.isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(
              transaction.isIncome
                  ? Icons.trending_up
                  : _categoryIcon(transaction.category),
              color: color,
              size: 20,
            ),
          ),
          title: Text(transaction.title,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
            '${transaction.category} • ${fmt.format(transaction.date)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: Text(
            '$sign ${currency.format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Alimentação':
        return Icons.restaurant;
      case 'Moradia':
        return Icons.home;
      case 'Serviços':
        return Icons.receipt;
      case 'Saúde':
        return Icons.favorite;
      default:
        return Icons.attach_money;
    }
  }
}
