import 'package:flutter/material.dart';
import '../../../../core/widgets/madrasa_app_bar_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/l10n/app_translations.dart';

class AddEditUserPage extends ConsumerStatefulWidget {
  final User? user;

  const AddEditUserPage({super.key, this.user});

  @override
  ConsumerState<AddEditUserPage> createState() => _AddEditUserPageState();
}

class _AddEditUserPageState extends ConsumerState<AddEditUserPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _userIdController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pinController;
  late TextEditingController _classJamatController;

  UserType _selectedType = UserType.student;
  UserStatus _selectedStatus = UserStatus.active;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.user != null;
    final t = ref.watch(translationProvider);

    _userIdController =
        TextEditingController(text: isEdit ? widget.user!.userId : '');
    _nameController =
        TextEditingController(text: isEdit ? widget.user!.name : '');
    _phoneController =
        TextEditingController(text: isEdit ? widget.user!.phone : '');
    // We don't show the hashed PIN. If edit, leave empty unless they want to change it.
    _pinController = TextEditingController();
    _classJamatController =
        TextEditingController(text: isEdit ? widget.user!.classJamat : '');

    _selectedType = isEdit ? widget.user!.type : UserType.student;
    _selectedStatus = isEdit ? widget.user!.status : UserStatus.active;
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _classJamatController.dispose();
    super.dispose();
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.user != null;
      final t = ref.watch(translationProvider);

      // If it's a new non-student user, PIN is required.
      if (!isEdit &&
          _selectedType != UserType.student &&
          _pinController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পিন নম্বর আবশ্যক')),
        );
        return;
      }

      String finalPinHash = isEdit ? (widget.user!.pin ?? '') : '';
      if (_pinController.text.isNotEmpty) {
        finalPinHash = UserRepository.hashPin(_pinController.text);
      }

      final user = User(
        userId: isEdit ? widget.user!.userId : _userIdController.text,
        name: _nameController.text,
        type: _selectedType,
        status: _selectedStatus,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        pin: finalPinHash,
        classJamat: _classJamatController.text.isNotEmpty
            ? _classJamatController.text
            : null,
        lastUpdated: DateTime.now(),
      );

      try {
        final repository = ref.read(userRepositoryProvider);
        await repository.upsertUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('সদস্য সফলভাবে সংরক্ষণ করা হয়েছে')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('সংরক্ষণে ত্রুটি: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final t = ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: MadrasaAppBarTitle(title: isEdit ? t.editUser : t.addUser),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: t.idNumberLabel,
                border: OutlineInputBorder(),
              ),
              enabled: !isEdit,
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: t.name,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? t.required : null,
            ),
            if (_selectedType != UserType.student) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: t.mobileNumberLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: isEdit ? t.newPinLabel : t.pinNumberLabel,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<UserType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: t.memberTypeLabel,
                border: OutlineInputBorder(),
              ),
              items: UserType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_translateUserType(type)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            if (_selectedType == UserType.student) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _classJamatController,
                decoration: InputDecoration(
                  labelText: t.classJamat,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<UserStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: t.status,
                border: OutlineInputBorder(),
              ),
              items: UserStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status == UserStatus.active
                      ? t.statusActive
                      : t.statusInactive),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saveUser,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t.saveBtn,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateUserType(UserType type) {
    switch (type) {
      case UserType.admin:
        return 'অ্যাডমিন';
      case UserType.teacher:
        return 'শিক্ষক';
      case UserType.student:
        return 'ছাত্র';
    }
  }
}
