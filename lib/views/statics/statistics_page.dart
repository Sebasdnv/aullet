import 'package:aullet/utils/color_utils.dart';
import 'package:aullet/viewmodels/statistics_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedYear = DateTime.now().year;
  int _year1 = DateTime.now().year;
  int? _month1;
  int _year2 = DateTime.now().year;
  int? _month2;
  Map<String, dynamic>? _comparison;

  String _monthName(int month) {
    const names = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    return names[month - 1];
  }

  double _computeMaxY(StatisticsViewModel vm, int year) {
    final totals = vm.calculateMothlyExpenses(year);
    double maxVal = 0;
    totals.forEach((_, value) {
      if (value > maxVal) maxVal = value;
    });
    return maxVal == 0 ? 100 : maxVal * 1.2;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsViewModel>().loadExpenses();
    });
  }

  Future<void> _doCompare() async {
    final vm = context.read<StatisticsViewModel>();
    final result = await vm.comparePeriods(_year1, _month1, _year2, _month2);
    setState(() => _comparison = result);
  }

  Widget _buildYearDropdown({required bool isFirst, required List<int> years}) {
    return DropdownButton<int>(
      value: isFirst ? _year1 : _year2,
      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
      onChanged: (y) {
        if (y != null) setState(() => isFirst ? _year1 = y : _year2 = y);
      },
    );
  }

  Widget _buildMonthDropdown({required bool isFirst}) {
    return DropdownButton<int?>(
      value: isFirst ? _month1 : _month2,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tutti i mesi')),
        ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m)))),
      ],
      onChanged: (m) => setState(() => isFirst ? _month1 = m : _month2 = m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final years = vm.allExpenses.map((e) => e.date.year).toSet().toList()..sort();
    if (!years.contains(_selectedYear)) years.insert(0, _selectedYear);

    final monthlyBreakdown = vm.calculateMonthlyBreakdown(_selectedYear);
    final categoryTotals = vm.calculatedExpensesByCategory(_selectedYear);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche'), centerTitle: true),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Andamento Mensile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (y) => setState(() => _selectedYear = y!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int?>(
                          value: vm.monthFilter,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tutti i mesi')),
                            ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m)))),
                          ],
                          onChanged: (m) => vm.monthFilter = m,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _computeMaxY(vm, _selectedYear),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: monthlyBreakdown.entries.map((monthEntry) {
                          double currentSum = 0;
                          final stackItems = monthEntry.value.entries.map((catEntry) {
                            final fromY = currentSum;
                            currentSum += catEntry.value;
                            return BarChartRodStackItem(
                              fromY, 
                              currentSum, 
                              parseHexColor(catEntry.key.color)
                            );
                          }).toList();

                          return BarChartGroupData(
                            x: monthEntry.key,
                            barRods: [
                              BarChartRodData(
                                toY: currentSum,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                rodStackItems: stackItems,
                              )
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) => Text(_monthName(v.toInt()), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 40),

                  const Text("Distribuzione per Categoria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  if (categoryTotals.isNotEmpty) ...[
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                          sections: categoryTotals.entries.map((e) {
                            return PieChartSectionData(
                              color: parseHexColor(e.key.color),
                              value: e.value,
                              title: '${e.value.toStringAsFixed(0)}',
                              radius: 100,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: categoryTotals.entries.map((e) {
                        final color = parseHexColor(e.key.color);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text("${e.key.name} (${e.value.toStringAsFixed(0)}€)", style: const TextStyle(fontSize: 13)),
                          ],
                        );
                      }).toList(),
                    ),
                  ] else 
                    const Center(child: Text("Nessuna spesa per questo periodo")),

                  const Divider(height: 40),

                  const Text("Confronta Periodi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        _buildYearDropdown(isFirst: true, years: years),
                        _buildMonthDropdown(isFirst: true),
                      ]),
                      const Icon(Icons.compare_arrows, size: 32, color: Colors.grey),
                      Column(children: [
                        _buildYearDropdown(isFirst: false, years: years),
                        _buildMonthDropdown(isFirst: false),
                      ]),
                    ],
                  ),
                  ElevatedButton(onPressed: _doCompare, child: const Text("CONFRONTA")),
                  if (_comparison != null) ...[
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    const Text("Periodo 1", style: TextStyle(fontSize: 12)),
                                    Text("€ ${_comparison!['period1'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text("Periodo 2", style: TextStyle(fontSize: 12)),
                                    Text("€ ${_comparison!['period2'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(
                              "Differenza: € ${_comparison!['difference'].toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${_comparison!['percentage'] >= 0 ? '+' : ''}${_comparison!['percentage'].toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _comparison!['percentage'] > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}