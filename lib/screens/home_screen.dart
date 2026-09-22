import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../services/translation_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String activeFY;
  const HomeScreen({super.key, required this.activeFY});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _period = 'Weekly';
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await StorageService.getTransactions(widget.activeFY);
    setState(() {
      _transactions = transactions;
      _calculateSummary();
      _loading = false;
    });
  }

  void _calculateSummary() {
    DateTime now = DateTime.now();
    DateTime start;
    int days = 0;
    int count = 0;

    switch (_period) {
      case 'Weekly':
        days = 7;
        count = 7;
        break;
      case 'Monthly':
        days = 30;
        count = 5;
        break;
      case 'Yearly':
        days = 365;
        count = 12;
        break;
      default:
        days = 365;
        count = 12;
        break;
    }

    start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

    double income = 0;
    double expense = 0;
    List<Transaction> filtered = [];
    
    Map<int, double> incomeMap = {};
    Map<int, double> expenseMap = {};

    for (var t in _transactions) {
      DateTime? tDate = DateTime.tryParse(t.date);
      if (tDate == null) continue;

      if (tDate.isAfter(start.subtract(const Duration(seconds: 1)))) {
        filtered.add(t);
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }

        int index = -1;
        if (_period == 'Weekly') {
          index = tDate.difference(start).inDays;
        } else if (_period == 'Monthly') {
          index = tDate.difference(start).inDays ~/ 7;
        } else if (_period == 'Yearly') {
          index = (tDate.year - start.year) * 12 + tDate.month - start.month;
        }

        if (index >= 0 && index < count) {
          if (t.type == TransactionType.income) {
            incomeMap[index] = (incomeMap[index] ?? 0) + t.amount;
          } else {
            expenseMap[index] = (expenseMap[index] ?? 0) + t.amount;
          }
        }
      }
    }

    _totalIncome = income;
    _totalExpense = expense;
    _filteredTransactions = filtered;
    _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    _incomeSpots = [];
    _expenseSpots = [];
    
    for (int i = 0; i < count; i++) {
      _incomeSpots.add(FlSpot(i.toDouble(), incomeMap[i] ?? 0));
      _expenseSpots.add(FlSpot(i.toDouble(), expenseMap[i] ?? 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummarySection(lang),
                        const SizedBox(height: 24),
                        _buildChartSection(lang),
                        const SizedBox(height: 24),
                        Text(
                          TranslationService.translate('recent_transactions', lang),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildTransactionList(lang),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummarySection(String lang) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(TranslationService.translate('income', lang), _totalIncome, Colors.green),
                _summaryItem(TranslationService.translate('expense', lang), _totalExpense, Colors.red),
              ],
            ),
            const Divider(height: 32),
            _summaryItem(TranslationService.translate('balance', lang), _totalIncome - _totalExpense, Colors.blue, isLarge: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color, {bool isLarge = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: isLarge ? 18 : 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isLarge ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(String lang) {
    double maxVal = 0;
    for (var s in _incomeSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    for (var s in _expenseSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    
    // Y-Axis intervals of 500
    maxVal = (maxVal / 500).ceil() * 500.0;
    if (maxVal == 0) maxVal = 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              TranslationService.translate('performance_chart', lang),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _period,
              items: ['Weekly', 'Monthly', 'Yearly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(TranslationService.translate(value.toLowerCase(), lang)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _period = val;
                    _calculateSummary();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.only(right: 16, top: 16),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: _incomeSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.3),
                        Colors.green.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: _expenseSpots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withValues(alpha: 0.3),
                        Colors.red.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: maxVal,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => _getBottomTitles(value, meta, lang),
                    reservedSize: 32,
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 500,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      );
                    },
                    reservedSize: 45,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  left: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta, String lang) {
    int index = value.toInt();
    DateTime now = DateTime.now();
    String text = '';

    try {
      if (_period == 'Weekly') {
        DateTime start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        text = DateFormat.E().format(start.add(Duration(days: index)));
      } else if (_period == 'Monthly') {
        text = 'W${index + 1}';
      } else if (_period == 'Yearly') {
        DateTime start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 364));
        text = DateFormat.MMM().format(DateTime(start.year, start.month + index, 1));
      }
    } catch (e) {
      text = '';
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(text, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
    );
  }

  Widget _buildTransactionList(String lang) {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(TranslationService.translate('no_transactions', lang)),
        ),
      );
    }
    // Show top 10 transactions
    int showCount = _filteredTransactions.length > 10 ? 10 : _filteredTransactions.length;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: showCount,
      itemBuilder: (context, index) {
        final tx = _filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tx.type == TransactionType.income ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                color: tx.type == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
            title: Text(tx.particular, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: ValueListenableBuilder<String>(
              valueListenable: dateTypeNotifier,
              builder: (context, dateType, _) {
                return Text(dateType == 'AD' 
                    ? tx.date 
                    : DateTime.parse(tx.date).toNepaliDateTime().format('yyyy-MM-dd'));
              },
            ),
            trailing: Text(
              'Rs. ${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tx.type == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
