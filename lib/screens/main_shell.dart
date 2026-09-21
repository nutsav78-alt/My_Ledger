import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'business_profile_screen.dart';
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

class MainShell extends StatefulWidget {
  final String activeFY;
  const MainShell({super.key, required this.activeFY});

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
  String _companyCategory = '';
  String _companyLogoPath = '';
  int _dataVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentFY = widget.activeFY;
    _loadFYList();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final profile = await StorageService.getBusinessProfile();
    if (profile != null) {
      setState(() {
        _companyName = profile['name'] ?? '';
        _companyEmail = profile['email'] ?? '';
        _companyContact = profile['contact'] ?? '';
        _companyCategory = profile['category'] ?? '';
        _companyLogoPath = profile['logoPath'] ?? '';
      });
    }
  }

  Future<void> _loadFYList() async {
    final list = await StorageService.getFinancialYears();
    setState(() => _fyList = list);
  }

  void _onFYChanged(String? newFY) async {
    if (newFY == 'ADD_NEW') {
      _showAddFYDialog();
      return;
    }
    if (newFY != null && newFY != _currentFY) {
      await StorageService.setActiveFY(newFY);
      setState(() => _currentFY = newFY);
    }
  }

  Future<void> _showAddFYDialog() async {
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final lang = languageNotifier.value;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('add_fy', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: InputDecoration(
                  labelText: TranslationService.translate('from_year', lang)),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: toController,
              decoration: InputDecoration(
                  labelText: TranslationService.translate('to_year', lang)),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(TranslationService.translate('cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              if (fromController.text.isNotEmpty && toController.text.isNotEmpty) {
                final newYear = '${fromController.text}-${toController.text}';
                if (!_fyList.contains(newYear)) {
                  setState(() {
                    _fyList.add(newYear);
                    _currentFY = newYear;
                  });
                  await StorageService.saveFinancialYears(_fyList);
                  await StorageService.setActiveFY(newYear);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(TranslationService.translate('save', lang)),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index, String lang) {
    switch (index) {
      case 0:
        return TranslationService.translate('home', lang);
      case 1:
        return TranslationService.translate('transaction', lang);
      case 2:
        return TranslationService.translate('party', lang);
      case 3:
        return TranslationService.translate('note', lang);
      default:
        return 'My Ledger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final bool isHomeTab = _currentIndex == 0;

        return Scaffold(
          appBar: AppBar(
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text(_getTitle(_currentIndex, lang)),
            ),
            centerTitle: false, // Ensure title stays on the left
            // 3-dash (Drawer) should only be on the first tab
            leading: isHomeTab 
                ? Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ) 
                : null,
            actions: [
              if (isHomeTab)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: DropdownButton<String>(
                    value: _currentFY.isEmpty ? null : _currentFY,
                    hint: Text(TranslationService.translate('select_fy', lang),
                        style: const TextStyle(fontSize: 14)),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    items: [
                      ..._fyList.map((String fy) {
                        return DropdownMenuItem<String>(
                          value: fy,
                          child: Text(fy,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }),
                      DropdownMenuItem<String>(
                        value: 'ADD_NEW',
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18, color: Colors.teal),
                            const SizedBox(width: 8),
                            Text(TranslationService.translate('add_fy', lang),
                                style: const TextStyle(color: Colors.teal)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: _onFYChanged,
                  ),
                ),
            ],
          ),
          drawer: isHomeTab ? Drawer(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.teal),
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: _companyLogoPath.isNotEmpty 
                            ? FileImage(File(_companyLogoPath)) 
                            : null,
                        child: _companyLogoPath.isEmpty 
                            ? const Icon(Icons.business, size: 40, color: Colors.teal) 
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _companyName.isNotEmpty ? _companyName : 'Company Name',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$_companyEmail | $_companyContact',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.teal.withValues(alpha: 0.05), // Light consistent background
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: Colors.teal),
                          title: Text(TranslationService.translate('view_profile', lang)),
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push(context, 
                              MaterialPageRoute(builder: (context) => const ProfileDetailsScreen()));
                            if (result == true) {
                              _loadBusinessProfile();
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: Text(TranslationService.translate('manage_fy', lang)),
                          onTap: () {
                            Navigator.pop(context);
                            _showAddFYDialog();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sync_alt, color: Colors.teal),
                          title: Text(TranslationService.translate('date_converter', lang)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings, color: Colors.teal),
                          title: Text(TranslationService.translate('settings', lang)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.switch_account, color: Colors.blue),
                          title: Text(TranslationService.translate('switch_profile', lang), style: const TextStyle(color: Colors.blue)),
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileListScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ) : null,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(activeFY: _currentFY, key: ValueKey('${_currentFY}home$_dataVersion')),
              TransactionScreen(activeFY: _currentFY, key: ValueKey('${_currentFY}tx$_dataVersion')),
              PartyScreen(activeFY: _currentFY, key: ValueKey('${_currentFY}party$_dataVersion')),
              NoteScreen(activeFY: _currentFY, key: ValueKey('${_currentFY}note$_dataVersion')),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                if (index == 0) _dataVersion++;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: TranslationService.translate('home', lang),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long),
                label: TranslationService.translate('transaction', lang),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: TranslationService.translate('party', lang),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.note),
                label: TranslationService.translate('note', lang),
              ),
            ],
          ),
        );
      },
    );
  }
}
