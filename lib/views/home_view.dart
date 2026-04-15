import 'package:aullet/models/category.dart';
import 'package:aullet/utils/color_utils.dart';
import 'package:aullet/utils/icon_map.dart';
import 'package:aullet/viewmodels/category_view_model.dart';
import 'package:aullet/viewmodels/expense_view_model.dart';
import 'package:aullet/views/new_expense_page.dart' show NewExpensePage;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseViewModel>().loadExpenses();
      context.read<CategoryViewModel>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final catVM = context.watch<CategoryViewModel>();

    return Scaffold(
      body: expenseVM.isLoading || catVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, expenseVM, catVM),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
            ),
            IconButton(onPressed: ()=> Navigator.pushNamed(context, '/statistics'), icon: const Icon(Icons.bar_chart))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewExpensePage()),
          ).then((_) {
            context.read<ExpenseViewModel>().loadExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody(BuildContext context, ExpenseViewModel expenseVM, CategoryViewModel catVM) {
    final expenses = expenseVM.expenses;
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Non ci sono spese inserite',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi Spesa'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewExpensePage()),
                ).then((_) {
                  expenseVM.loadExpenses();
                });
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final cat = catVM.categories.firstWhere(
          (c) => c.id == exp.categoryId,
          orElse: () => Category(id: '', name: 'Unknown', icon: 'category', color: 'FF000000'),
        );
        final iconData = iconMap[cat.icon] ?? Icons.category;
        final color = parseHexColor(cat.color);
        final date = exp.date;
        final formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

        return ListTile(
          leading: Icon(iconData, color: color),
          title: Text(
            '€ ${exp.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$formattedDate${exp.description != null && exp.description!.isNotEmpty ? '\n${exp.description}' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewExpensePage(expense: exp),
                    ),
                  ).then((_) => expenseVM.loadExpenses());
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmDialog(context, expenseVM, exp.id!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ExpenseViewModel expenseVM, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina Spesa'),
        content: const Text('Sei sicuro di voler eliminare questa spesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await expenseVM.deleteExpense(id);
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}