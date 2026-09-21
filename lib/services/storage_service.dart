import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/party.dart';
import '../models/note.dart';

class StorageService {
  static const String _fyKey = 'financial_years';
  static const String _activeFyKey = 'active_financial_year';
  static const String _partyKey = 'parties';
  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language';
  static const String _dateTypeKey = 'date_type';
  static const String _profilesListKey = 'business_profiles_list';
  static const String _activeProfileIdKey = 'active_profile_id';

  static Future<String> _getPrefix() async {
    final id = await getActiveProfileId();
    return id != null ? '${id}_' : '';
  }

  static Future<void> saveBusinessProfile({
    String? id,
    required String name,
    required String email,
    required String contact,
    required String category,
    String? logoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final profileData = {
      'id': profileId,
      'name': name,
      'email': email,
      'contact': contact,
      'category': category,
      'logoPath': logoPath ?? '',
    };

    // Save profile to the list of profiles
    List<String> profiles = prefs.getStringList(_profilesListKey) ?? [];
    int existingIndex = profiles.indexWhere((p) => json.decode(p)['id'] == profileId);
    if (existingIndex != -1) {
      profiles[existingIndex] = json.encode(profileData);
    } else {
      profiles.add(json.encode(profileData));
    }
    await prefs.setStringList(_profilesListKey, profiles);
    await prefs.setString(_activeProfileIdKey, profileId);
  }

  static Future<Map<String, String>?> getBusinessProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeProfileIdKey);
    if (activeId == null) return null;

    final profiles = prefs.getStringList(_profilesListKey) ?? [];
    for (var p in profiles) {
      final decoded = json.decode(p);
      if (decoded['id'] == activeId) {
        return Map<String, String>.from(decoded);
      }
    }
    return null;
  }

  static Future<List<Map<String, String>>> getAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = prefs.getStringList(_profilesListKey) ?? [];
    return profiles.map((p) => Map<String, String>.from(json.decode(p))).toList();
  }

  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileIdKey);
  }

  static Future<void> setActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileIdKey, id);
  }

  static Future<bool> isProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileIdKey) != null;
  }

  // Stubs for removed login system to prevent build errors
  static Future<void> setLoggedIn(bool value) async {}
  static Future<bool> isLoggedIn() async => false;
  static Future<void> saveRememberMe(bool v, {String? email, String? password}) async {}
  static Future<Map<String, dynamic>> getRememberMe() async => {'remember': false};
  static Future<void> saveUser({required String email, required String password}) async {}
  static Future<Map<String, String>?> getUser() async => null;

  static Future<List<String>> getFinancialYears() async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${prefix}$_fyKey') ?? [];
  }

  static Future<void> saveFinancialYears(List<String> years) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${prefix}$_fyKey', years);
  }

  static Future<String?> getActiveFY() async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${prefix}$_activeFyKey');
  }

  static Future<void> setActiveFY(String fy) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${prefix}$_activeFyKey', fy);
  }

  // Transactions
  static Future<List<Transaction>> getTransactions(String fy) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${prefix}transactions_$fy');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Transaction.fromMap(e)).toList();
  }

  static Future<void> saveTransactions(String fy, List<Transaction> transactions) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString('${prefix}transactions_$fy', data);
  }

  static Future<double> getPartyBalance(Party party) async {
    final ledger = await getPartyLedger(party.id);
    double balance = party.openingBalance * (party.type == BalanceType.dr ? 1 : -1);
    for (var entry in ledger) {
      balance += (entry.debit - entry.credit);
    }
    return balance;
  }

  // Parties
  static Future<List<Party>> getParties(String fy) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${prefix}parties_$fy');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Party.fromMap(e)).toList();
  }

  static Future<void> saveParties(String fy, List<Party> parties) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(parties.map((e) => e.toMap()).toList());
    await prefs.setString('${prefix}parties_$fy', data);
  }

  static Future<List<PartyTransaction>> getPartyLedger(String partyId) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${prefix}ledger_$partyId');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => PartyTransaction.fromMap(e)).toList();
  }

  static Future<void> savePartyLedger(String partyId, List<PartyTransaction> ledger) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(ledger.map((e) => e.toMap()).toList());
    await prefs.setString('${prefix}ledger_$partyId', data);
  }

  // Notes
  static Future<List<Note>> getNotes(String fy) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${prefix}notes_$fy');
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Note.fromMap(e)).toList();
  }

  static Future<void> saveNotes(String fy, List<Note> notes) async {
    final prefix = await _getPrefix();
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(notes.map((e) => e.toMap()).toList());
    await prefs.setString('${prefix}notes_$fy', data);
  }

  // Settings
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'English';
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  static Future<String> getDateType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateTypeKey) ?? 'AD';
  }

  static Future<void> saveDateType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateTypeKey, type);
  }
}
