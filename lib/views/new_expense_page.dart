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
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  Category? _selectedCategory;
  late DateTime _selectedDate;

  bool _isRecurring = false;
  int _selectedYear = DateTime.now().year;
  int _selectedDay = DateTime.now().day;
  List<int> _selectedMonths = [];
  bool _allMonths = false;

  final List<String> _monthNames = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _updateDateDisplay();

    if (widget.expense != null) {
      _amountCtrl.text = widget.expense!.amount.toString();
      _descCtrl.text = widget.expense!.description ?? '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categories = context.read<CategoryViewModel>().categories;
        setState(() {
          _selectedCategory = categories.firstWhere(
            (c) => c.id == widget.expense!.categoryId,
            orElse: () => categories.first,
          );
        });
      });
    }
  }

  void _updateDateDisplay() {
    _dateCtrl.text =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateDisplay();
      });
    }
  }

  void _toggleMonth(int monthIdx) {
    setState(() {
      if (_selectedMonths.contains(monthIdx)) {
        _selectedMonths.remove(monthIdx);
        _allMonths = false;
      } else {
        _selectedMonths.add(monthIdx);
        if (_selectedMonths.length == 12) _allMonths = true;
      }
    });
  }

  void _toggleAllMonths(bool? value) {
    setState(() {
      _allMonths = value ?? false;
      if (_allMonths) {
        _selectedMonths = List.generate(12, (i) => i + 1);
      } else {
        _selectedMonths = [];
      }
    });
  }

  void _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona una categoria!')));
      return;
    }

    final amount = double.parse(_amountCtrl.text);
    final user = Supabase.instance.client.auth.currentUser;
    final vm = context.read<ExpenseViewModel>();

    if (!_isRecurring) {
      final exp = Expense(
        id: widget.expense?.id,
        userId: user!.id,
        categoryId: _selectedCategory!.id,
        amount: amount,
        date: _selectedDate,
        description: _descCtrl.text,
      );

      widget.expense == null
          ? await vm.addExpense(exp)
          : await vm.updateExpense(exp);
    } else {
      if (_selectedMonths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona almeno un mese!')),
        );
        return;
      }

      _selectedMonths.sort();

      for (int i = 0; i < _selectedMonths.length; i++) {
        int month = _selectedMonths[i];
        int lastDayOfMonth = DateTime(_selectedYear, month + 1, 0).day;
        int actualDay = _selectedDay > lastDayOfMonth ? lastDayOfMonth : _selectedDay;

        String? targetId;
        if (widget.expense != null && i == 0) {
          targetId = widget.expense!.id;
        }

        final exp = Expense(
          id: targetId,
          userId: user!.id,
          categoryId: _selectedCategory!.id,
          amount: amount,
          date: DateTime(_selectedYear, month, actualDay),
          description: _descCtrl.text,
        );

        if (exp.id != null) {
          await vm.updateExpense(exp);
        } else {
          await vm.addExpense(exp);
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Nuova Spesa' : 'Modifica'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Importo (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Inserisci un importo';
                  if (double.tryParse(value) == null) return 'Inserisci un numero valido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrizione (Opzionale)',
                  border: OutlineInputBorder(),
                ),
                // VALIDAZIONE RIMOSSA: ora è opzionale
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildTypeRectangle(false, 'Singola', Icons.exposure_plus_1),
                  const SizedBox(width: 12),
                  _buildTypeRectangle(true, 'Costante', Icons.repeat),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isRecurring)
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                _buildRecurringSection(),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Categoria",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory?.id == cat.id;
                  final color = parseHexColor(cat.color);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconMap[cat.icon] ?? Icons.category,
                            color: isSelected ? color : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                  child: const Text('SALVA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRectangle(bool isConstant, String label, IconData icon) {
    bool isSelected = _isRecurring == isConstant;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRecurring = isConstant),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Anno',
                  border: OutlineInputBorder(),
                ),
                items: [DateTime.now().year, DateTime.now().year + 1]
                    .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                    .toList(),
                onChanged: (val) => setState(() => _selectedYear = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Giorno',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(31, (i) => i + 1)
                    .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDay = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text("Tutti i mesi"),
          value: _allMonths,
          onChanged: _toggleAllMonths,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        Wrap(
          spacing: 8,
          children: List.generate(12, (index) {
            final monthNum = index + 1;
            final isSelected = _selectedMonths.contains(monthNum);
            return FilterChip(
              label: Text(_monthNames[index]),
              selected: isSelected,
              onSelected: (_) => _toggleMonth(monthNum),
            );
          }),
        ),
      ],
    );
  }
}