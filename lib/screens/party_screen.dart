import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as ndp;
import 'package:share_plus/share_plus.dart';

import '../services/storage_service.dart';
import '../models/party.dart';
import '../services/translation_service.dart';
import '../main.dart';

class PartyScreen extends StatefulWidget {
  final String activeFY;

  const PartyScreen({
    super.key,
    required this.activeFY,
  });

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  List<Party> _parties = [];
  Map<String, double> _balances = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final parties = await StorageService.getParties(widget.activeFY);

    final Map<String, double> balances = {};

    for (final party in parties) {
      balances[party.id] =
          await StorageService.getPartyBalance(party);
    }

    if (!mounted) return;

    setState(() {
      _parties = parties;
      _balances = balances;
      _loading = false;
    });
  }

  void _showPartyOptions(Party party) {
    final lang = languageNotifier.value;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(
              TranslationService.translate('edit', lang),
            ),
            onTap: () {
              Navigator.pop(context);
              _editParty(party);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: Text(
              TranslationService.translate('delete', lang),
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteParty(party);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _editParty(Party party) async {
    final lang = languageNotifier.value;

    final nameController =
        TextEditingController(text: party.name);
    final contactController =
        TextEditingController(text: party.contact);
    final emailController =
        TextEditingController(text: party.email);
    final balanceController =
        TextEditingController(
      text: party.openingBalance.toString(),
    );

    BalanceType selectedType = party.type;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              TranslationService.translate(
                'edit_party',
                lang,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'name',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'contact',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'email',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: balanceController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'opening_balance',
                        lang,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${TranslationService.translate('type', lang)}: ',
                      ),
                      Radio<BalanceType>(
                        value: BalanceType.dr,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      Text(
                        TranslationService.translate(
                          'debit',
                          lang,
                        ),
                      ),
                      Radio<BalanceType>(
                        value: BalanceType.cr,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      Text(
                        TranslationService.translate(
                          'credit',
                          lang,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  TranslationService.translate(
                    'cancel',
                    lang,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }

                  final updatedParty = Party(
                    id: party.id,
                    name: nameController.text.trim(),
                    contact: contactController.text.trim(),
                    email: emailController.text.trim(),
                    openingBalance:
                        double.tryParse(
                              balanceController.text,
                            ) ??
                            0,
                    type: selectedType,
                  );

                  final index = _parties.indexWhere(
                    (p) => p.id == party.id,
                  );

                  if (index != -1) {
                    setState(() {
                      _parties[index] = updatedParty;
                    });

                    await StorageService.saveParties(
                      widget.activeFY,
                      _parties,
                    );

                    await _loadData();
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  TranslationService.translate(
                    'save',
                    lang,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    balanceController.dispose();
  }

  Future<void> _deleteParty(Party party) async {
    final lang = languageNotifier.value;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate(
            'delete',
            lang,
          ),
        ),
        content: Text(
          TranslationService.translate(
            'confirm_delete',
            lang,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: Text(
              TranslationService.translate(
                'cancel',
                lang,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(
              TranslationService.translate(
                'delete',
                lang,
              ),
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _parties.removeWhere(
        (p) => p.id == party.id,
      );
      _balances.remove(party.id);
    });

    await StorageService.saveParties(
      widget.activeFY,
      _parties,
    );

    await _loadData();
  }

  Future<void> _addParty() async {
    final lang = languageNotifier.value;

    if (widget.activeFY.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TranslationService.translate(
              'select_fy',
              lang,
            ),
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final balanceController = TextEditingController();

    BalanceType selectedType = BalanceType.dr;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              TranslationService.translate(
                'add_party',
                lang,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'name',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'contact',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'email',
                        lang,
                      ),
                    ),
                  ),
                  TextField(
                    controller: balanceController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'opening_balance',
                        lang,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${TranslationService.translate('type', lang)}: ',
                      ),
                      Radio<BalanceType>(
                        value: BalanceType.dr,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      Text(
                        TranslationService.translate(
                          'debit',
                          lang,
                        ),
                      ),
                      Radio<BalanceType>(
                        value: BalanceType.cr,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      Text(
                        TranslationService.translate(
                          'credit',
                          lang,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  TranslationService.translate(
                    'cancel',
                    lang,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }

                  final newParty = Party(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    name: nameController.text.trim(),
                    contact: contactController.text.trim(),
                    email: emailController.text.trim(),
                    openingBalance:
                        double.tryParse(
                              balanceController.text,
                            ) ??
                            0,
                    type: selectedType,
                  );

                  setState(() {
                    _parties.add(newParty);
                  });

                  await StorageService.saveParties(
                    widget.activeFY,
                    _parties,
                  );

                  await _loadData();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  TranslationService.translate(
                    'save',
                    lang,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    contactController.dispose();
    emailController.dispose();
    balanceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _parties.isEmpty
                  ? Center(
                      child: Text(
                        TranslationService.translate(
                          'no_data',
                          lang,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      itemCount: _parties.length,
                      itemBuilder: (context, index) {
                        final party = _parties[index];
                        final balance =
                            _balances[party.id] ?? 0;

                        return TweenAnimationBuilder<double>(
                          duration: Duration(
                            milliseconds:
                                300 + (index * 50),
                          ),
                          tween: Tween(
                            begin: 0.0,
                            end: 1.0,
                          ),
                          builder:
                              (context, value, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                20 * (1 - value),
                              ),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            margin:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            elevation: 2,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Hero(
                                tag:
                                    'party-icon-${party.id}',
                                child: CircleAvatar(
                                  backgroundColor:
                                      Colors.teal.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                              title: Text(
                                party.name,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${party.contact} | ${party.email}',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${balance.abs()}',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
                                      color: balance >= 0
                                          ? Colors.teal
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    balance >= 0
                                        ? TranslationService
                                            .translate(
                                            'debit',
                                            lang,
                                          )
                                        : TranslationService
                                            .translate(
                                            'credit',
                                            lang,
                                          ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: balance >= 0
                                          ? Colors.teal
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () =>
                                  Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PartyLedgerScreen(
                                    party: party,
                                  ),
                                ),
                              ).then(
                                (_) => _loadData(),
                              ),
                              onLongPress: () =>
                                  _showPartyOptions(party),
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: AnimatedScale(
            scale: 1.0,
            duration:
                const Duration(milliseconds: 300),
            child: FloatingActionButton(
              onPressed: _addParty,
              backgroundColor: Colors.teal,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PartyLedgerScreen extends StatefulWidget {
  final Party party;

  const PartyLedgerScreen({
    super.key,
    required this.party,
  });

  @override
  State<PartyLedgerScreen> createState() =>
      _PartyLedgerScreenState();
}

class _PartyLedgerScreenState
    extends State<PartyLedgerScreen> {
  List<PartyTransaction> _ledger = [];
  List<double> _runningBalances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final ledger =
        await StorageService.getPartyLedger(
      widget.party.id,
    );

    double balance = widget.party.openingBalance *
        (widget.party.type == BalanceType.dr ? 1 : -1);

    final List<double> balances = [balance];

    for (final entry in ledger) {
      balance += entry.debit - entry.credit;
      balances.add(balance);
    }

    if (!mounted) return;

    setState(() {
      _ledger = ledger;
      _runningBalances = balances;
      _loading = false;
    });
  }

  void _showEntryOptions(PartyTransaction entry) {
    final lang = languageNotifier.value;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(
              TranslationService.translate(
                'edit',
                lang,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _editEntry(entry);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: Text(
              TranslationService.translate(
                'delete',
                lang,
              ),
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _editEntry(
    PartyTransaction entry,
  ) async {
    final lang = languageNotifier.value;

    final particularController =
        TextEditingController(
      text: entry.particular,
    );

    final amountController =
        TextEditingController(
      text: (entry.debit > 0
              ? entry.debit
              : entry.credit)
          .toString(),
    );

    String selectedEntryType =
        entry.debit > 0 ? 'Debit' : 'Credit';

    DateTime selectedDate =
        DateFormat('yyyy-MM-dd').parse(entry.date);

    ndp.NepaliDateTime selectedNepaliDate =
        ndp.NepaliDateTime.now();

    if (dateTypeNotifier.value != 'AD') {
      try {
        selectedNepaliDate =
            ndp.NepaliDateTime.parse(entry.date);
      } catch (_) {
        try {
          selectedNepaliDate =
              ndp.NepaliDateTime.fromDateTime(
            selectedDate,
          );
        } catch (_) {
          selectedNepaliDate =
              ndp.NepaliDateTime.now();
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              TranslationService.translate(
                'edit_ledger_entry',
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
                      labelText:
                          TranslationService.translate(
                        'particular',
                        lang,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedEntryType,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'type',
                        lang,
                      ),
                    ),
                    items: ['Debit', 'Credit']
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              TranslationService.translate(
                                type.toLowerCase(),
                                lang,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedEntryType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'amount',
                        lang,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      dateTypeNotifier.value == 'AD'
                          ? '${TranslationService.translate('date', lang)}: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'
                          : '${TranslationService.translate('date', lang)}: ${ndp.NepaliDateFormat('yyyy-MM-dd').format(selectedNepaliDate)}',
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                    ),
                    onTap: () async {
                      if (dateTypeNotifier.value ==
                          'AD') {
                        final picked =
                            await showDatePicker(
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
                          initialDate:
                              selectedNepaliDate,
                          firstDate:
                              ndp.NepaliDateTime(2000),
                          lastDate:
                              ndp.NepaliDateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedNepaliDate =
                                picked;
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
                onPressed: () =>
                    Navigator.pop(context),
                child: Text(
                  TranslationService.translate(
                    'cancel',
                    lang,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(
                            amountController.text,
                          ) ??
                          0;

                  if (amount <= 0) return;

                  final updatedEntry =
                      PartyTransaction(
                    id: entry.id,
                    partyId: widget.party.id,
                    date: dateTypeNotifier.value ==
                            'AD'
                        ? DateFormat('yyyy-MM-dd')
                            .format(selectedDate)
                        : selectedNepaliDate
                            .toDateTime()
                            .toIso8601String()
                            .split('T')[0],
                    particular:
                        particularController.text,
                    debit:
                        selectedEntryType == 'Debit'
                            ? amount
                            : 0,
                    credit:
                        selectedEntryType == 'Credit'
                            ? amount
                            : 0,
                  );

                  final index =
                      _ledger.indexWhere(
                    (e) => e.id == entry.id,
                  );

                  if (index != -1) {
                    setState(() {
                      _ledger[index] = updatedEntry;
                    });

                    await StorageService
                        .savePartyLedger(
                      widget.party.id,
                      _ledger,
                    );

                    await _loadLedger();
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  TranslationService.translate(
                    'save',
                    lang,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    particularController.dispose();
    amountController.dispose();
  }

  Future<void> _deleteEntry(
    PartyTransaction entry,
  ) async {
    final lang = languageNotifier.value;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate(
            'delete',
            lang,
          ),
        ),
        content: Text(
          TranslationService.translate(
            'confirm_delete',
            lang,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: Text(
              TranslationService.translate(
                'cancel',
                lang,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(
              TranslationService.translate(
                'delete',
                lang,
              ),
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _ledger.removeWhere(
        (e) => e.id == entry.id,
      );
    });

    await StorageService.savePartyLedger(
      widget.party.id,
      _ledger,
    );

    await _loadLedger();
  }

  Future<void> _addEntry() async {
    final lang = languageNotifier.value;

    final particularController =
        TextEditingController();
    final amountController =
        TextEditingController();

    String selectedEntryType = 'Debit';

    DateTime selectedDate = DateTime.now();
    ndp.NepaliDateTime selectedNepaliDate =
        ndp.NepaliDateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              TranslationService.translate(
                'add_ledger_entry',
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
                      labelText:
                          TranslationService.translate(
                        'particular',
                        lang,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedEntryType,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'type',
                        lang,
                      ),
                    ),
                    items: ['Debit', 'Credit']
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              TranslationService.translate(
                                type.toLowerCase(),
                                lang,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedEntryType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText:
                          TranslationService.translate(
                        'amount',
                        lang,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      dateTypeNotifier.value == 'AD'
                          ? '${TranslationService.translate('date', lang)}: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'
                          : '${TranslationService.translate('date', lang)}: ${ndp.NepaliDateFormat('yyyy-MM-dd').format(selectedNepaliDate)}',
                    ),
                    trailing: const Icon(
                      Icons.calendar_today,
                    ),
                    onTap: () async {
                      if (dateTypeNotifier.value ==
                          'AD') {
                        final picked =
                            await showDatePicker(
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
                          initialDate:
                              selectedNepaliDate,
                          firstDate:
                              ndp.NepaliDateTime(2000),
                          lastDate:
                              ndp.NepaliDateTime.now(),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedNepaliDate =
                                picked;
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
                onPressed: () =>
                    Navigator.pop(context),
                child: Text(
                  TranslationService.translate(
                    'cancel',
                    lang,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(
                            amountController.text,
                          ) ??
                          0;

                  if (amount <= 0) return;

                  final newEntry =
                      PartyTransaction(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    partyId: widget.party.id,
                    date: dateTypeNotifier.value ==
                            'AD'
                        ? DateFormat('yyyy-MM-dd')
                            .format(selectedDate)
                        : selectedNepaliDate
                            .toDateTime()
                            .toIso8601String()
                            .split('T')[0],
                    particular:
                        particularController.text,
                    debit:
                        selectedEntryType == 'Debit'
                            ? amount
                            : 0,
                    credit:
                        selectedEntryType == 'Credit'
                            ? amount
                            : 0,
                  );

                  setState(() {
                    _ledger.add(newEntry);
                  });

                  await StorageService
                      .savePartyLedger(
                    widget.party.id,
                    _ledger,
                  );

                  await _loadLedger();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  TranslationService.translate(
                    'save',
                    lang,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    particularController.dispose();
    amountController.dispose();
  }

  void _shareLedger(
    double opening,
    String lang,
  ) {
    String content =
        '${TranslationService.translate('ledger', lang)}: ${widget.party.name}\n';

    content +=
        '${TranslationService.translate('opening_balance', lang)}: ${widget.party.openingBalance} ${widget.party.type == BalanceType.dr ? TranslationService.translate('debit', lang) : TranslationService.translate('credit', lang)}\n\n';

    content +=
        '${TranslationService.translate('date', lang)} | ${TranslationService.translate('particular', lang)} | ${TranslationService.translate('debit', lang)} | ${TranslationService.translate('credit', lang)} | ${TranslationService.translate('balance', lang)}\n';

    content +=
        '------------------------------------------------\n';

    double running = opening;

    for (final entry in _ledger) {
      running += entry.debit - entry.credit;

      content +=
          '${entry.date} | ${entry.particular} | ${entry.debit} | ${entry.credit} | ${running.abs()} ${running >= 0 ? TranslationService.translate('debit', lang) : TranslationService.translate('credit', lang)}\n';
    }

    Share.share(content);
  }

  Widget _buildLedgerItem(
    dynamic e,
    double runningBalance,
    int index,
    String lang,
    String dateType, {
    bool isHeader = false,
    bool isOpening = false,
  }) {
    String displayDate = '';

    if (!isHeader) {
      if (isOpening) {
        displayDate = '-';
      } else {
        if (dateType == 'AD') {
          displayDate = e.date;
        } else {
          try {
            final nepaliDate =
                ndp.NepaliDateTime.fromDateTime(
              DateTime.parse(e.date),
            );

            displayDate =
                ndp.NepaliDateFormat(
              'yyyy-MM-dd',
            ).format(nepaliDate);
          } catch (_) {
            displayDate = e.date;
          }
        }
      }
    } else {
      displayDate =
          TranslationService.translate(
        'date',
        lang,
      );
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds:
            300 + (index * 30).clamp(0, 500),
      ),
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            20 * (1 - value),
            0,
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        onLongPress:
            isOpening || isHeader
                ? null
                : () => _showEntryOptions(e),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color:
                isHeader ? Colors.grey[200] : null,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  displayDate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHeader
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  isHeader
                      ? TranslationService.translate(
                          'particular',
                          lang,
                        )
                      : (isOpening
                          ? TranslationService.translate(
                              'opening_balance',
                              lang,
                            )
                          : e.particular),
                  style: TextStyle(
                    fontWeight: isHeader
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  isHeader
                      ? TranslationService.translate(
                          'debit',
                          lang,
                        )
                      : (isOpening
                          ? (widget.party.type ==
                                  BalanceType.dr
                              ? widget.party
                                  .openingBalance
                                  .toString()
                              : '0')
                          : (e.debit > 0
                              ? e.debit.toString()
                              : '-')),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isHeader
                        ? null
                        : Colors.teal,
                    fontWeight: isHeader
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  isHeader
                      ? TranslationService.translate(
                          'credit',
                          lang,
                        )
                      : (isOpening
                          ? (widget.party.type ==
                                  BalanceType.cr
                              ? widget.party
                                  .openingBalance
                                  .toString()
                              : '0')
                          : (e.credit > 0
                              ? e.credit.toString()
                              : '-')),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isHeader
                        ? null
                        : Colors.red,
                    fontWeight: isHeader
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  isHeader
                      ? TranslationService.translate(
                          'balance',
                          lang,
                        )
                      : '${runningBalance.abs()} ${runningBalance >= 0 ? TranslationService.translate('debit', lang) : TranslationService.translate('credit', lang)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        isHeader ? 12 : 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialRunningBalance =
        widget.party.openingBalance *
            (widget.party.type ==
                    BalanceType.dr
                ? 1
                : -1);

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<String>(
          valueListenable: dateTypeNotifier,
          builder: (context, dateType, _) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                title: Row(
                  children: [
                    Hero(
                      tag:
                          'party-icon-${widget.party.id}',
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Colors.white,
                        child: Icon(
                          Icons.person,
                          color: Colors.teal,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${TranslationService.translate('ledger', lang)}: ${widget.party.name}',
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.share),
                    onPressed: () =>
                        _shareLedger(
                      initialRunningBalance,
                      lang,
                    ),
                  ),
                ],
              ),
              body: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        _buildLedgerItem(
                          null,
                          0,
                          0,
                          lang,
                          dateType,
                          isHeader: true,
                        ),
                        Expanded(
                          child:
                              ListView.builder(
                            itemCount:
                                _ledger.length + 1,
                            itemBuilder:
                                (context, index) {
                              if (index == 0) {
                                return _buildLedgerItem(
                                  null,
                                  _runningBalances[0],
                                  1,
                                  lang,
                                  dateType,
                                  isOpening: true,
                                );
                              }

                              return _buildLedgerItem(
                                _ledger[index - 1],
                                _runningBalances[index],
                                index + 1,
                                lang,
                                dateType,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
              floatingActionButton:
                  FloatingActionButton(
                onPressed: _addEntry,
                backgroundColor: Colors.teal,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }
}