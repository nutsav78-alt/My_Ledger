import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';

import 'home_screen.dart';
import 'transaction_screen.dart';
import 'party_screen.dart';
import 'note_screen.dart';
import 'settings_screen.dart';
import 'profile_list_screen.dart';
import 'profile_details_screen.dart';
import 'lock_settings_screen.dart';
import 'help_screen.dart';

class MainShell extends StatefulWidget {
  final String activeFY;

  const MainShell({
    super.key,
    required this.activeFY,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late String _currentFY;

  List<String> _fyList = [];

  String _companyName = '';
  String _companyEmail = '';
  String _companyContact = '';
  String _companyLogoPath = '';

  int _dataVersion = 0;

  static final ValueNotifier<String> sortNotifier =
      ValueNotifier<String>('date_wise');

  @override
  void initState() {
    super.initState();

    _currentFY = widget.activeFY;

    _loadFYList();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final profile = await StorageService.getBusinessProfile();

    if (!mounted) return;

    if (profile != null) {
      setState(() {
        _companyName = profile['name'] ?? '';
        _companyEmail = profile['email'] ?? '';
        _companyContact = profile['contact'] ?? '';
        _companyLogoPath = profile['logoPath'] ?? '';
      });
    }
  }

  Future<void> _loadFYList() async {
    final list = await StorageService.getFinancialYears();

    if (!mounted) return;

    setState(() {
      _fyList = list;
    });
  }

  Future<void> _onFYChanged(String? newFY) async {
    if (newFY == 'ADD_NEW') {
      await _showAddFYDialog();
      return;
    }

    if (newFY != null && newFY != _currentFY) {
      await StorageService.setActiveFY(newFY);

      if (!mounted) return;

      setState(() {
        _currentFY = newFY;
        _dataVersion++;
      });
    }
  }

  Future<void> _showAddFYDialog() async {
    final fromController = TextEditingController();
    final toController = TextEditingController();

    final lang = languageNotifier.value;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            TranslationService.translate('add_fy', lang),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: TranslationService.translate(
                    'from_year',
                    lang,
                  ),
                ),
              ),
              TextField(
                controller: toController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: TranslationService.translate(
                    'to_year',
                    lang,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                TranslationService.translate('cancel', lang),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final from = fromController.text.trim();
                final to = toController.text.trim();

                if (from.isEmpty || to.isEmpty) {
                  return;
                }

                final newYear = '$from-$to';

                if (!_fyList.contains(newYear)) {
                  _fyList.add(newYear);

                  await StorageService.saveFinancialYears(
                    _fyList,
                  );
                }

                await StorageService.setActiveFY(newYear);

                if (!mounted) return;

                setState(() {
                  _currentFY = newYear;
                  _dataVersion++;
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                TranslationService.translate('save', lang),
              ),
            ),
          ],
        );
      },
    );

    fromController.dispose();
    toController.dispose();

    await _loadFYList();
  }

  void _showSortOptions(String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                TranslationService.translate(
                  'sort_by',
                  lang,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text(
                TranslationService.translate(
                  'a_z',
                  lang,
                ),
              ),
              onTap: () {
                sortNotifier.value = 'a_z';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.sort_by_alpha,
                textDirection: TextDirection.rtl,
              ),
              title: Text(
                TranslationService.translate(
                  'z_a',
                  lang,
                ),
              ),
              onTap: () {
                sortNotifier.value = 'z_a';
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(
                TranslationService.translate(
                  'date_wise',
                  lang,
                ),
              ),
              onTap: () {
                sortNotifier.value = 'date_wise';
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _getTitle(int index, String lang) {
    switch (index) {
      case 0:
        return TranslationService.translate('home', lang);

      case 1:
        return TranslationService.translate(
          'transaction',
          lang,
        );

      case 2:
        return TranslationService.translate(
          'party',
          lang,
        );

      case 3:
        return TranslationService.translate(
          'note',
          lang,
        );

      default:
        return 'My Ledger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final isHomeTab = _currentIndex == 0;

        return Scaffold(
          appBar: AppBar(
            title: isHomeTab
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: const Icon(Icons.menu),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTitle(
                          _currentIndex,
                          lang,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentFY.isEmpty
                              ? null
                              : _currentFY,
                          hint: Text(
                            TranslationService.translate(
                              'select_fy',
                              lang,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.teal,
                          ),
                          items: [
                            ..._fyList.map(
                              (fy) {
                                return DropdownMenuItem<String>(
                                  value: fy,
                                  child: Text(
                                    fy,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            DropdownMenuItem<String>(
                              value: 'ADD_NEW',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    TranslationService.translate(
                                      'add_fy',
                                      lang,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: _onFYChanged,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _getTitle(
                      _currentIndex,
                      lang,
                    ),
                  ),
            centerTitle: false,
            titleSpacing: 4,
            leading: null,
            actions: [
              if (!isHomeTab)
                IconButton(
                  icon: const Icon(
                    Icons.sort,
                    color: Colors.teal,
                  ),
                  onPressed: () {
                    _showSortOptions(lang);
                  },
                ),
            ],
          ),

          drawer: isHomeTab
              ? Drawer(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.teal,
                        padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(context)
                                  .padding
                                  .top +
                              24,
                          left: 20,
                          right: 20,
                          bottom: 24,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _companyLogoPath.isNotEmpty
                                      ? FileImage(
                                          File(
                                            _companyLogoPath,
                                          ),
                                        )
                                      : null,
                              child:
                                  _companyLogoPath.isEmpty
                                      ? const Icon(
                                          Icons.business,
                                          size: 40,
                                          color: Colors.teal,
                                        )
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _companyName.isNotEmpty
                                  ? _companyName
                                  : 'Company Name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                            Text(
                              '$_companyEmail | $_companyContact',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'view_profile',
                                  lang,
                                ),
                              ),
                              onTap: () async {
                                Navigator.pop(context);

                                final result =
                                    await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileDetailsScreen(),
                                  ),
                                );

                                if (result == true) {
                                  _loadBusinessProfile();
                                }
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'manage_fy',
                                  lang,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showAddFYDialog();
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.lock_outline,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'app_lock',
                                  lang,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LockSettingsScreen(),
                                  ),
                                );
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.sync_alt,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'date_converter',
                                  lang,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.settings,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'settings',
                                  lang,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.help_outline,
                                color: Colors.teal,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'help',
                                  lang,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const HelpScreen(),
                                  ),
                                );
                              },
                            ),

                            const Divider(),

                            ListTile(
                              leading: const Icon(
                                Icons.switch_account,
                                color: Colors.blue,
                              ),
                              title: Text(
                                TranslationService.translate(
                                  'switch_profile',
                                  lang,
                                ),
                                style: const TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileListScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : null,

          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                activeFY: _currentFY,
                key: ValueKey(
                  '${_currentFY}home$_dataVersion',
                ),
              ),
              TransactionScreen(
                activeFY: _currentFY,
                key: ValueKey(
                  '${_currentFY}tx$_dataVersion',
                ),
              ),
              PartyScreen(
                activeFY: _currentFY,
                key: ValueKey(
                  '${_currentFY}party$_dataVersion',
                ),
              ),
              NoteScreen(
                activeFY: _currentFY,
                key: ValueKey(
                  '${_currentFY}note$_dataVersion',
                ),
              ),
            ],
          ),

          bottomNavigationBar:
              BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;

                if (index == 0) {
                  _dataVersion++;
                }
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: TranslationService.translate(
                  'home',
                  lang,
                ),
              ),
              BottomNavigationBarItem(
                icon: const Icon(
                  Icons.receipt_long,
                ),
                label: TranslationService.translate(
                  'transaction',
                  lang,
                ),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: TranslationService.translate(
                  'party',
                  lang,
                ),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.note),
                label: TranslationService.translate(
                  'note',
                  lang,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
