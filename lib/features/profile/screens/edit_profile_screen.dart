import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
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

  @override
  void initState() {
    super.initState();
    _initial = ref.read(currentUserProvider) ??
        const User(id: 0, profile: 'STUDENT');
    _gender = _initial.gender;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _email, _phone, _birthdate, _street,
      _houseNumber, _zipCode, _city, _pickup, _plate,
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
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
          );
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      showAppSnack(context, 'Profiel bijgewerkt');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gegevens bewerken')),
      body: Center(
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
                        decoration:
                            const InputDecoration(labelText: 'Voornaam'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration:
                            const InputDecoration(labelText: 'Achternaam'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mailadres'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Verplicht veld';
                    if (!value.contains('@')) {
                      return 'Vul een geldig e-mailadres in';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Geslacht'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Man')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Vrouw')),
                    DropdownMenuItem(value: 'UNKNOWN', child: Text('Onbekend')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthdate,
                  readOnly: true,
                  onTap: _pickBirthdate,
                  decoration: const InputDecoration(
                    labelText: 'Geboortedatum',
                    hintText: 'jjjj-mm-dd',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Telefoonnummer'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Verplicht veld'
                      : null,
                ),
                const SizedBox(height: 24),
                Text('Adres',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _street,
                        decoration: const InputDecoration(labelText: 'Straat'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _houseNumber,
                        decoration:
                            const InputDecoration(labelText: 'Huisnr.'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
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
                        decoration:
                            const InputDecoration(labelText: 'Postcode'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'Plaats'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Verplicht veld'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pickup,
                  decoration:
                      const InputDecoration(labelText: 'Ophaallocatie'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Kenteken'),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Opslaan'),
                ),
              ],
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
