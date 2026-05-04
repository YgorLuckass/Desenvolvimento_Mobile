// lib/views/analysis/analysis_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txVm = context.watch<TransactionViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Análise Financeira',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Categorias'),
            Tab(icon: Icon(Icons.list_alt), text: 'Movimentações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryAnalysisTab(vm: txVm),
          _TransactionListTab(vm: txVm),
        ],
      ),
    );
  }
}

// ── Tab 1: Category Analysis ──────────────────────────────────────────────────

class _CategoryAnalysisTab extends StatelessWidget {
  final TransactionViewModel vm;
  const _CategoryAnalysisTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final byCategory = vm.expenseByCategory;
    final total = byCategory.values.fold(0.0, (s, v) => s + v);
    final colors = [
      AppTheme.chartColor1, AppTheme.chartColor2, AppTheme.chartColor3,
      AppTheme.chartColor4, AppTheme.chartColor5, AppTheme.chartColor6,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Row
          Row(
            children: [
              _StatCard('Receitas', currency.format(vm.totalIncome), AppTheme.income),
              const SizedBox(width: 10),
              _StatCard('Despesas', currency.format(vm.totalExpense), AppTheme.expense),
              const SizedBox(width: 10),
              _StatCard(
                'Economia',
                '${vm.savingsRate.toStringAsFixed(1)}%',
                vm.savingsRate >= 0 ? AppTheme.income : AppTheme.expense,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pie Chart
          if (byCategory.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Despesas por Categoria',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: byCategory.entries.toList().asMap().entries.map((e) {
                            final idx = e.key;
                            final entry = e.value;
                            final pct = (entry.value / total) * 100;
                            return PieChartSectionData(
                              color: colors[idx % colors.length],
                              value: entry.value,
                              title: '${pct.toStringAsFixed(0)}%',
                              radius: 70,
                              titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: byCategory.entries.toList().asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final pct = (entry.value / total) * 100;
                    return _CategoryRow(
                      label: entry.key,
                      amount: currency.format(entry.value),
                      percent: pct,
                      color: colors[idx % colors.length],
                    );
                  }).toList(),
                ),
              ),
            ),
          ] else
            const Center(child: Text('Nenhuma despesa registrada.')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final String amount;
  final double percent;
  final Color color;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              ]),
              Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Full Transaction List ──────────────────────────────────────────────

class _TransactionListTab extends StatelessWidget {
  final TransactionViewModel vm;
  const _TransactionListTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final txs = vm.transactions;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final fmt = DateFormat('dd/MM/yyyy');

    if (txs.isEmpty) {
      return const Center(child: Text('Nenhuma transação registrada.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: txs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        final tx = txs[i];
        final color = tx.isIncome ? AppTheme.income : AppTheme.expense;
        final sign = tx.isIncome ? '+' : '-';

        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          onDismissed: (_) => vm.removeTransaction(tx.id),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  tx.isIncome ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(tx.title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              subtitle: Text(
                '${tx.category} · ${fmt.format(tx.date)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              trailing: Text(
                '$sign ${currency.format(tx.amount)}',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        );
      },
    );
  }
}
