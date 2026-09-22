import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as ndp;
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../services/translation_service.dart';
import '../main.dart';

class TransactionScreen extends StatefulWidget {
  final String activeFY;

  const TransactionScreen({super.key, required this.activeFY});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions =
        await StorageService.getTransactions(widget.activeFY);

    if (!mounted) return;

    setState(() {
      _transactions = transactions;
      _loading = false;
    });

    _sortByDate();
  }

  void _sortByDate() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _addTransaction(TransactionType type) async {
    final lang = languageNotifier.value;

    if (widget.activeFY.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.translate('select_fy', lang),
          ),
        ),
      );
      return;
    }

    final particularController = TextEditingController();
    final amountController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    ndp.NepaliDateTime selectedNepaliDate =
        ndp.NepaliDateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            TranslationService.translate(
              type == TransactionType.income ? 'income' : 'expense',
              lang,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: particularController,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate(
                      'particular',
                      lang,
                    ),
                  ),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate(
                      'amount',
                      lang,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    dateTypeNotifier.value == 'AD'
                        ? '${TranslationService.translate('date', lang)}: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'
                        : '${TranslationService.translate('date', lang)}: ${ndp.NepaliDateFormat('yyyy-MM-dd').format(selectedNepaliDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    if (dateTypeNotifier.value == 'AD') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    } else {
                      final picked =
                          await ndp.showNepaliDatePicker(
                        context: context,
                        initialDate: selectedNepaliDate,
                        firstDate: ndp.NepaliDateTime(2000),
                        lastDate: ndp.NepaliDateTime.now(),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedNepaliDate = picked;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                TranslationService.translate('cancel', lang),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final dateType = dateTypeNotifier.value;

                if (particularController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final amount =
                      double.tryParse(amountController.text);

                  if (amount == null) {
                    return;
                  }

                  final newTx = Transaction(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    date: dateType == 'AD'
                        ? DateFormat('yyyy-MM-dd')
                            .format(selectedDate)
                        : selectedNepaliDate
                            .toDateTime()
                            .toIso8601String()
                            .split('T')[0],
                    particular: particularController.text,
                    amount: amount,
                    type: type,
                    financialYear: widget.activeFY,
                  );

                  setState(() {
                    _transactions.insert(0, newTx);
                    _sortByDate();
                  });

                  await StorageService.saveTransactions(
                    widget.activeFY,
                    _transactions,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(
                TranslationService.translate('save', lang),
              ),
            ),
          ],
        ),
      ),
    );

    particularController.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<String>(
          valueListenable: dateTypeNotifier,
          builder: (context, dateType, _) {
            return Scaffold(
              body: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _transactions.isEmpty
                              ? Center(
                                  child: Text(
                                    TranslationService.translate(
                                      'no_transactions',
                                      lang,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _transactions.length,
                                  itemBuilder: (context, index) {
                                    final tx = _transactions[index];

                                    String displayDate;

                                    if (dateType == 'AD') {
                                      displayDate = tx.date;
                                    } else {
                                      final parsedDate =
                                          DateTime.tryParse(tx.date);

                                      if (parsedDate != null) {
                                        final nepaliDate =
                                            ndp.NepaliDateTime
                                                .fromDateTime(
                                          parsedDate,
                                        );

                                        displayDate =
                                            nepaliDate.format(
                                          'yyyy-MM-dd',
                                        );
                                      } else {
                                        displayDate = tx.date;
                                      }
                                    }

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            tx.type ==
                                                    TransactionType
                                                        .income
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.red.withValues(
                                                    alpha: 0.1,
                                                  ),
                                        child: Icon(
                                          tx.type ==
                                                  TransactionType
                                                      .income
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: tx.type ==
                                                  TransactionType
                                                      .income
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      title: Text(
                                        tx.particular,
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(displayDate),
                                          const SizedBox(width: 8),
                                          Text(
                                            tx.type.name,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        'Rs. ${tx.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: tx.type ==
                                                  TransactionType
                                                      .income
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      onLongPress: () async {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) =>
                                              AlertDialog(
                                            title: Text(
                                              TranslationService
                                                  .translate(
                                                'delete_transaction',
                                                lang,
                                              ),
                                            ),
                                            content: Text(
                                              TranslationService
                                                  .translate(
                                                'delete_confirm',
                                                lang,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: Text(
                                                  TranslationService
                                                      .translate(
                                                    'cancel',
                                                    lang,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: Text(
                                                  TranslationService
                                                      .translate(
                                                    'delete',
                                                    lang,
                                                  ),
                                                  style:
                                                      const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          setState(() {
                                            _transactions
                                                .removeAt(index);
                                          });

                                          await StorageService
                                              .saveTransactions(
                                            widget.activeFY,
                                            _transactions,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _addTransaction(
                                    TransactionType.income,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    TranslationService.translate(
                                      'income',
                                      lang,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _addTransaction(
                                    TransactionType.expense,
                                  ),
                                  icon: const Icon(Icons.remove),
                                  label: Text(
                                    TranslationService.translate(
                                      'expense',
                                      lang,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}