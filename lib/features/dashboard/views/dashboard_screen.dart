import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/news_service.dart';
import '../../../models/transaction.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../analysis/views/analysis_screen.dart';
import '../../auth/views/auth_screen.dart';
import '../../../widgets/add_transaction_sheet.dart';

final newsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  return NewsService().getFinanceNews();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final userId = authState.userId ?? '';
    final TransactionState txState = ref.watch(transactionViewModelProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(transactionViewModelProvider(userId).notifier).loadTransactions(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, ref, authState.userName ?? 'usuário')),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BalanceCard(
                  balance: txState.totalBalance,
                  income: txState.totalIncome,
                  expenses: txState.totalExpenses,
                  currency: _currency,
                ),
              )),
              SliverToBoxAdapter(child: _buildNewsSection(context, ref)),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              )),
              if (txState.status == TransactionStatus.loading)
                SliverToBoxAdapter(child: _buildShimmerList())
              else if (txState.transactions.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = txState.recentTransactions[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _TransactionTile(tx: tx, currency: _currency, userId: userId),
                      );
                    },
                    childCount: txState.recentTransactions.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionSheet(userId: userId),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String userName) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Olá, $userName 👋',
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
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => AuthScreen()));
                }
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Notícias Financeiras',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 140,
          child: newsAsync.when(
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (_, __) => _buildNewsShimmer(),
            ),
            error: (e, _) => Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Sem conexão', style: TextStyle(color: Colors.grey.shade500)),
              ]),
            ),
            data: (articles) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: articles.length,
              itemBuilder: (ctx, i) => _NewsCard(article: articles[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade600,
      child: Column(
        children: List.generate(4, (_) => Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 68,
          decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(14)),
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade600),
        const SizedBox(height: 16),
        Text('Nenhuma transação ainda', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    ));
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1D9E75).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text(currency.format(balance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _MiniStat(label: '↑ Receitas', value: currency.format(income), color: Colors.greenAccent.shade100)),
          const SizedBox(width: 12),
          Expanded(child: _MiniStat(label: '↓ Despesas', value: currency.format(expenses), color: Colors.red.shade200)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(article.source, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(article.publishedAt.length >= 10 ? article.publishedAt.substring(0, 10) : article.publishedAt,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ]),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction tx;
  final NumberFormat currency;
  final String userId;

  const _TransactionTile({required this.tx, required this.currency, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = categoryIcons[tx.category] ?? '📦';
    final color = tx.isIncome ? Colors.green.shade500 : Colors.red.shade400;
    final bgColor = tx.isIncome ? Colors.green.shade900.withOpacity(0.3) : Colors.red.shade900.withOpacity(0.3);

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(transactionViewModelProvider(userId).notifier).deleteTransaction(tx.id),
      child: GestureDetector(
        onLongPress: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionSheet(userId: userId, editTransaction: tx),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade800),
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
              Text('${tx.isIncome ? '+' : '-'}${currency.format(tx.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(DateFormat('dd/MM').format(tx.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}