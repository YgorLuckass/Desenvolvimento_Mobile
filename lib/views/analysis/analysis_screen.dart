import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../models/transaction.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final List<Color> _chartColors = [
    const Color(0xFF1D9E75), const Color(0xFF378ADD), const Color(0xFFEF9F27),
    const Color(0xFFD4537E), const Color(0xFF7F77DD), const Color(0xFFE24B4A),
    const Color(0xFF639922), const Color(0xFF888780),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FinanceViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise Financeira', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Gráficos'), Tab(text: 'Categorias'), Tab(text: 'Histórico')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChartsTab(vm: vm, chartColors: _chartColors, currency: _currency),
          _CategoriesTab(vm: vm, chartColors: _chartColors, currency: _currency),
          _HistoryTab(vm: vm, currency: _currency),
        ],
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  final FinanceViewModel vm;
  final List<Color> chartColors;
  final NumberFormat currency;

  const _ChartsTab({required this.vm, required this.chartColors, required this.currency});

  @override
  Widget build(BuildContext context) {
    final byCategory = vm.expensesByCategory;
    final total = vm.totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: _SummaryCard(label: 'Receitas', value: currency.format(vm.totalIncome), color: const Color(0xFF1D9E75))),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Despesas', value: currency.format(vm.totalExpenses), color: const Color(0xFFE24B4A))),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(label: 'Saldo', value: currency.format(vm.totalBalance), color: const Color(0xFF378ADD))),
        ]),
        const SizedBox(height: 24),
        if (byCategory.isNotEmpty) ...[
          Text('Distribuição de Gastos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(PieChartData(
              sections: byCategory.entries.toList().asMap().entries.map((e) {
                final pct = total > 0 ? (e.value.value / total * 100) : 0;
                return PieChartSectionData(
                  value: e.value.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  color: chartColors[e.key % chartColors.length],
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            )),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 8,
            children: byCategory.entries.toList().asMap().entries.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: chartColors[e.key % chartColors.length], shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.value.key, style: const TextStyle(fontSize: 12)),
              ],
            )).toList(),
          ),
        ] else
          const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('Nenhuma despesa registrada ainda', style: TextStyle(color: Colors.grey)),
          )),
        const SizedBox(height: 24),
        _MonthlyBarChart(vm: vm),
      ]),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final FinanceViewModel vm;
  const _MonthlyBarChart({required this.vm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    final monthLabels = months.map((m) => DateFormat('MMM', 'pt_BR').format(m)).toList();

    double maxVal = 1;
    final incomeData = months.map((m) {
      final sum = vm.transactions
          .where((tx) => tx.isIncome && tx.date.year == m.year && tx.date.month == m.month)
          .fold(0.0, (s, tx) => s + tx.amount);
      if (sum > maxVal) maxVal = sum;
      return sum;
    }).toList();

    final expenseData = months.map((m) {
      final sum = vm.transactions
          .where((tx) => !tx.isIncome && tx.date.year == m.year && tx.date.month == m.month)
          .fold(0.0, (s, tx) => s + tx.amount);
      if (sum > maxVal) maxVal = sum;
      return sum;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Últimos 6 meses',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          maxY: maxVal * 1.2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(monthLabels[v.toInt()], style: const TextStyle(fontSize: 11)),
            )),
          ),
          barGroups: List.generate(6, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: incomeData[i], color: const Color(0xFF1D9E75), width: 10, borderRadius: BorderRadius.circular(4)),
              BarChartRodData(toY: expenseData[i], color: const Color(0xFFE24B4A), width: 10, borderRadius: BorderRadius.circular(4)),
            ],
            barsSpace: 4,
          )),
        )),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _LegendDot(color: const Color(0xFF1D9E75), label: 'Receitas'),
        const SizedBox(width: 20),
        _LegendDot(color: const Color(0xFFE24B4A), label: 'Despesas'),
      ]),
    ]);
  }
}

class _CategoriesTab extends StatelessWidget {
  final FinanceViewModel vm;
  final List<Color> chartColors;
  final NumberFormat currency;

  const _CategoriesTab({required this.vm, required this.chartColors, required this.currency});

  @override
  Widget build(BuildContext context) {
    final byCategory = vm.expensesByCategory;
    final total = vm.totalExpenses;
    final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const Center(child: Text('Nenhuma despesa registrada', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final entry = sorted[i];
        final pct = total > 0 ? entry.value / total : 0.0;
        final color = chartColors[i % chartColors.length];
        final icon = categoryIcons[entry.key] ?? '📦';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              Text(currency.format(entry.value),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(pct * 100).toStringAsFixed(1)}% do total de gastos',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
        );
      },
    );
  }
}

class _HistoryTab extends StatefulWidget {
  final FinanceViewModel vm;
  final NumberFormat currency;
  const _HistoryTab({required this.vm, required this.currency});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final all = List<Transaction>.from(widget.vm.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final filtered = _filter == 'Receitas'
        ? all.where((tx) => tx.isIncome).toList()
        : _filter == 'Despesas'
            ? all.where((tx) => !tx.isIncome).toList()
            : all;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: ['Todos', 'Receitas', 'Despesas'].map((f) {
            final sel = _filter == f;
            return GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f, style: TextStyle(
                  color: sel ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600, fontSize: 13,
                )),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Text('Nenhuma transação encontrada', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final tx = filtered[i];
                  final icon = categoryIcons[tx.category] ?? '📦';
                  final color = tx.isIncome ? Colors.green.shade500 : Colors.red.shade400;
                  final bgColor = tx.isIncome ? Colors.green.shade50 : Colors.red.shade50;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${tx.category} • ${DateFormat('dd/MM/yyyy').format(tx.date)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      ])),
                      Text('${tx.isIncome ? '+' : '-'}${widget.currency.format(tx.amount)}',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}