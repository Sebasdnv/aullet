import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/category_view_model.dart';
import '../utils/color_utils.dart';
import '../utils/icon_map.dart';

class NewExpensePage extends StatefulWidget {
  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Category? _selectedCategory;

  void _save(BuildContext context) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci importo e categoria')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final newExp = Expense(
      userId: user!.id,
      categoryId: _selectedCategory!.id,
      amount: amount,
      date: DateTime.now(),
      description: _descCtrl.text,
    );

    await context.read<ExpenseViewModel>().addExpense(newExp);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Spesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Importo (€)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descrizione (opzionale)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Seleziona Categoria:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory?.id == cat.id;
                  final color = parseHexColor(cat.color);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                        border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconMap[cat.icon] ?? Icons.category, color: color),
                          const SizedBox(height: 4),
                          Text(cat.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text('SALVA SPESA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}