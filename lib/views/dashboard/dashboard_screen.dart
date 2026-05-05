import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../models/transaction.dart';
import '../../widgets/add_transaction_sheet.dart';
import '../analysis/analysis_screen.dart';
import '../auth/auth_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Olá, ${vm.loggedInUser?.split('@').first ?? 'usuário'} 👋',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    Text('Dashboard',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.bar_chart_rounded),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AnalysisScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () async {
                        await vm.logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()));
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _BalanceCard(
                balance: vm.totalBalance,
                income: vm.totalIncome,
                expenses: vm.totalExpenses,
                currency: _currency,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transações Recentes',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AnalysisScreen())),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: vm.transactions.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: vm.recentTransactions.length,
                      itemBuilder: (ctx, i) => _TransactionTile(
                          tx: vm.recentTransactions[i], currency: _currency),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet(),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance, income, expenses;
  final NumberFormat currency;

  const _BalanceCard({required this.balance, required this.income,
      required this.expenses, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D9E75), Color(0xFF0F6E56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1D9E75).withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text(currency.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _MiniStat(label: '↑ Receitas',
              value: currency.format(income), color: Colors.greenAccent.shade100)),
          const SizedBox(width: 12),
          Expanded(child: _MiniStat(label: '↓ Despesas',
              value: currency.format(expenses), color: Colors.red.shade200)),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final NumberFormat currency;
  const _TransactionTile({required this.tx, required this.currency});

  @override
  Widget build(BuildContext context) {
    final icon = categoryIcons[tx.category] ?? '📦';
    final color = tx.isIncome ? Colors.green.shade500 : Colors.red.shade400;
    final bgColor = tx.isIncome ? Colors.green.shade50 : Colors.red.shade50;
    final sign = tx.isIncome ? '+' : '-';

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<FinanceViewModel>().deleteTransaction(tx.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(tx.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$sign${currency.format(tx.amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(DateFormat('dd/MM').format(tx.date),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Nenhuma transação ainda',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Toque em "Adicionar" para começar',
          style: TextStyle(color: Colors.grey.shade300, fontSize: 13)),
    ]));
  }
}