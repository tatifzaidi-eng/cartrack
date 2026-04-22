import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseType _selectedType = ExpenseType.entretien;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;
    final expense = Expense(
      type: _selectedType,
      amount: double.parse(_amountCtrl.text),
      date: _selectedDate,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    context.read<AppProvider>().addExpense(expense);
    _amountCtrl.clear();
    _noteCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Dépense enregistrée ✓'),
          backgroundColor: AppTheme.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final vehicle = provider.currentVehicle;
        final expenses = vehicle?.expenses ?? [];
        final sorted = [...expenses]
          ..sort((a, b) => b.date.compareTo(a.date));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💳 Ajouter une dépense',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<ExpenseType>(
                          value: _selectedType,
                          decoration:
                              const InputDecoration(labelText: 'Type'),
                          items: ExpenseType.values.map((t) {
                            return DropdownMenuItem(
                                value: t,
                                child: Text('${t.emoji} ${t.label}'));
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedType = v!),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _amountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Montant (MAD)',
                                    hintText: 'ex: 800'),
                                validator: (v) =>
                                    (v == null ||
                                            double.tryParse(v) == null)
                                        ? 'Requis'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 15, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd/MM/yy')
                                            .format(_selectedDate),
                                        style:
                                            const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Note (optionnel)'),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveExpense,
                            child: const Text('✓ Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📋 Liste des dépenses',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (sorted.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Aucune dépense enregistrée',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ...sorted.map((e) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.expenseTypeBg(e.type.name),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(e.type.emoji,
                                      style:
                                          const TextStyle(fontSize: 18)),
                                ),
                              ),
                              title: Text(e.note ?? e.type.label,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.expenseTypeBg(e.type.name),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(e.type.label,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.expenseTypeColor(
                                            e.type.name))),
                              ),
                              isThreeLine: false,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                          '${e.amount.toStringAsFixed(0)} MAD',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          DateFormat('dd/MM/yy')
                                              .format(e.date),
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(
                                        context, provider, e.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color:
                                                const Color(0xFFFCA5A5)),
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: AppTheme.red),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Supprimer cette dépense ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              provider.deleteExpense(id);
              Navigator.pop(context);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
