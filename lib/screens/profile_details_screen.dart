import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../main.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  String? _selectedCategory;
  String? _profileId;
  File? _logoFile;
  String? _existingLogoPath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'agriculture', 'automobiles', 'bakery', 'clothing',
    'electric_electronix', 'education', 'stationary', 'personal',
    'healthcare', 'jwellery', 'hotel', 'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.getBusinessProfile();
    if (profile != null) {
      setState(() {
        _profileId = profile['id'];
        _nameController.text = profile['name'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _contactController.text = profile['contact'] ?? '';
        _selectedCategory = profile['category'];
        _existingLogoPath = profile['logoPath'];
      });
    }
  }

  Future<void> _pickLogo() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  void _saveChanges() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) return;

    await StorageService.saveBusinessProfile(
      id: _profileId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      contact: _contactController.text.trim(),
      category: _selectedCategory ?? 'other',
      logoPath: _logoFile?.path ?? _existingLogoPath,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('profile_details', lang)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage: _logoFile != null 
                        ? FileImage(_logoFile!) 
                        : (_existingLogoPath != null && _existingLogoPath!.isNotEmpty 
                            ? FileImage(File(_existingLogoPath!)) 
                            : null),
                    child: (_logoFile == null && (_existingLogoPath == null || _existingLogoPath!.isEmpty))
                        ? const Icon(Icons.business, size: 40, color: Colors.teal)
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate('company_name', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate('email_label', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate('contact', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: TranslationService.translate('business_category', lang),
                    border: const OutlineInputBorder(),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(TranslationService.translate(cat, lang)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
