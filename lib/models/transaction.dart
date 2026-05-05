class Transaction {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'category': category,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'],
        date: DateTime.parse(json['date']),
        category: json['category'],
      );
}

const List<String> incomeCategories = [
  'Salário', 'Freelance', 'Investimentos', 'Outros',
];

const List<String> expenseCategories = [
  'Alimentação', 'Moradia', 'Transporte', 'Saúde',
  'Lazer', 'Educação', 'Roupas', 'Outros',
];

const Map<String, String> categoryIcons = {
  'Salário': '💼', 'Freelance': '💻', 'Investimentos': '📈',
  'Alimentação': '🛒', 'Moradia': '🏠', 'Transporte': '🚗',
  'Saúde': '🏥', 'Lazer': '🎭', 'Educação': '📚',
  'Roupas': '👕', 'Outros': '📦',
};