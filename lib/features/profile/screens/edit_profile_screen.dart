import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final User _initial;

  late final _firstName = TextEditingController(text: _initial.firstName);
  late final _lastName = TextEditingController(text: _initial.lastName);
  late final _email = TextEditingController(text: _initial.email);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _birthdate = TextEditingController(text: _initial.birthdate);
  late final _street = TextEditingController(text: _initial.street);
  late final _houseNumber = TextEditingController(text: _initial.houseNumber);
  late final _zipCode = TextEditingController(text: _initial.zipCode);
  late final _city = TextEditingController(text: _initial.city);
  late final _pickup = TextEditingController(text: _initial.pickupLocation);
  late final _plate = TextEditingController(text: _initial.licensePlate);

  String? _gender;
  bool _busy = false;
  XFile? _carImage;

  @override
  void initState() {
    super.initState();
    _initial =
        ref.read(currentUserProvider) ?? const User(id: 0, profile: 'STUDENT');
    _gender = _initial.gender;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _birthdate,
      _street,
      _houseNumber,
      _zipCode,
      _city,
      _pickup,
      _plate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final initial = _parseDate(_initial.birthdate) ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthdate.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _pickCarImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (picked != null) {
      setState(() => _carImage = picked);
    }
  }

  void _clearCarImage() {
    setState(() => _carImage = null);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            profile: {
              'firstName': _firstName.text.trim(),
              'lastName': _lastName.text.trim(),
              if (_gender != null) 'gender': _gender,
              if (_birthdate.text.trim().isNotEmpty)
                'birthdate': _birthdate.text.trim(),
              'phone': _phone.text.trim(),
              'street': _street.text.trim(),
              'houseNumber': _houseNumber.text.trim(),
              'zipCode': _zipCode.text.trim(),
              'city': _city.text.trim(),
              if (_pickup.text.trim().isNotEmpty)
                'pickupLocation': _pickup.text.trim(),
              if (_plate.text.trim().isNotEmpty)
                'licensePlate': _plate.text.trim(),
            },
            email: _email.text.trim(),
            carImage: _initial.profile == 'INSTRUCTOR' ? _carImage : null,
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      showAppSnack(context, context.l10n.editProfileUpdated);
      context.pop();
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        decoration: InputDecoration(
                          labelText: l10n.registerFirstName,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration: InputDecoration(
                          labelText: l10n.registerLastName,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return l10n.registerRequired;
                    if (!value.contains('@')) {
                      return l10n.loginEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                    labelText: l10n.editProfileGender,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'MALE',
                      child: Text(l10n.editProfileGenderMale),
                    ),
                    DropdownMenuItem(
                      value: 'FEMALE',
                      child: Text(l10n.editProfileGenderFemale),
                    ),
                    DropdownMenuItem(
                      value: 'UNKNOWN',
                      child: Text(l10n.editProfileGenderUnknown),
                    ),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthdate,
                  readOnly: true,
                  onTap: _pickBirthdate,
                  decoration: InputDecoration(
                    labelText: l10n.registerBirthdate,
                    hintText: l10n.registerBirthdateHint,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.registerPhone),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.registerRequired
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.registerAddress,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _street,
                        decoration: InputDecoration(
                          labelText: l10n.registerStreet,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _houseNumber,
                        decoration: InputDecoration(
                          labelText: l10n.registerHouseNumber,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zipCode,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: l10n.registerZipCode,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _city,
                        decoration: InputDecoration(
                          labelText: l10n.registerCity,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.registerRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pickup,
                  decoration: InputDecoration(
                    labelText: l10n.studentsPickupLabel,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.profileLicensePlate,
                  ),
                ),
                if (_initial.profile == 'INSTRUCTOR') ...[
                  const SizedBox(height: 14),
                  Text(
                    l10n.registerCarImage,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _carImage == null
                              ? Text(
                                  l10n.registerCarImageSelect,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _carImage!.name.isNotEmpty
                                            ? _carImage!.name
                                            : l10n.genericSuccess,
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 8),
                        if (_carImage == null)
                          FilledButton.tonalIcon(
                            onPressed: _pickCarImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n.registerCarImageSelect),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _clearCarImage,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(l10n.delete),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}
