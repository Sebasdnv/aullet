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

  String _monthName(int month) {
    const names = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return names[month - 1];
  }

  // QUESTA È LA FUNZIONE CHE MANCAVA
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final years = vm.allExpenses.map((e) => e.date.year).toSet().toList()..sort();
    if (!years.contains(_selectedYear)) years.insert(0, _selectedYear);

    final monthlyTotals = vm.calculateMothlyExpenses(_selectedYear);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche'), centerTitle: true),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          items: years.map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          )).toList(),
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
                            ...List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_monthName(m)),
                            )),
                          ],
                          onChanged: (m) => vm.monthFilter = m,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _computeMaxY(vm, _selectedYear),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (v, meta) {
                                final val = monthlyTotals[v.toInt()] ?? 0;
                                return Text(val > 0 ? val.toStringAsFixed(0) : '', 
                                       style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) => Text(_monthName(v.toInt()), 
                                       style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        // AGGIUNTE LE BARRE REALI
                        barGroups: monthlyTotals.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.blue,
                                width: 15,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}