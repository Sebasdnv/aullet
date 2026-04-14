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
  final Expense? expense;

  const NewExpensePage({super.key, this.expense});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  Category? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _dateCtrl.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    
    if (widget.expense != null) {
      _amountCtrl.text = widget.expense!.amount.toString();
      _descCtrl.text = widget.expense!.description ?? '';
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
      });
    }
  }

  void _save(BuildContext context) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci importo e categoria')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final expData = Expense(
      id: widget.expense?.id,
      userId: user!.id,
      categoryId: _selectedCategory!.id,
      amount: amount,
      date: _selectedDate,
      description: _descCtrl.text,
    );

    if (widget.expense == null) {
      await context.read<ExpenseViewModel>().addExpense(expData);
    } else {
      await context.read<ExpenseViewModel>().updateExpense(expData);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    if (widget.expense != null && _selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.firstWhere(
        (c) => c.id == widget.expense!.categoryId,
        orElse: () => categories.first,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Nuova Spesa' : 'Modifica Spesa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Importo (€)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descrizione (opzionale)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Seleziona Categoria:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = _selectedCategory?.id == cat.id;
                final color = parseHexColor(cat.color);
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconMap[cat.icon] ?? Icons.category, 
                             color: isSelected ? color : Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text(widget.expense == null ? 'SALVA SPESA' : 'CONFERMA MODIFICA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}