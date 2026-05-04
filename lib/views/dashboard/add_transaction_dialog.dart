// lib/views/dashboard/add_transaction_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/transaction_viewmodel.dart';
import '../../utils/app_theme.dart';

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _category = 'Alimentação';

  final _expenseCategories = [
    'Alimentação', 'Moradia', 'Serviços', 'Saúde', 'Lazer', 'Transporte', 'Outros'
  ];
  final _incomeCategories = ['Trabalho', 'Freelance', 'Investimentos', 'Outros'];

  List<String> get _categories =>
      _type == TransactionType.expense ? _expenseCategories : _incomeCategories;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final tx = TransactionModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      type: _type,
      date: DateTime.now(),
      category: _category,
    );
    context.read<TransactionViewModel>().addTransaction(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Nova Transação', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type toggle
              Row(
                children: TransactionType.values.map((t) {
                  final isSelected = _type == t;
                  final color = t == TransactionType.income ? AppTheme.income : AppTheme.expense;
                  final label = t == TransactionType.income ? 'Receita' : 'Despesa';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = t;
                        _category = _categories.first;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
                          border: Border.all(
                              color: isSelected ? color : Colors.grey.shade200, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(label,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? color : Colors.grey.shade500)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: AppTheme.inputDecoration('Descrição', Icons.edit_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: AppTheme.inputDecoration('Valor (R\$)', Icons.attach_money),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: AppTheme.inputDecoration('Categoria', Icons.category_outlined),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
