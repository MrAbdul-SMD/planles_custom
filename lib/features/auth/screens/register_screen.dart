import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets.dart';
import '../providers/auth_provider.dart';

/// Registration is a two-step OTP flow: fill in the form → the API mails a
/// code → enter the code → the account is created and we are signed in.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _passwordRules =
      'Minimaal 8 tekens met een kleine letter, hoofdletter en cijfer';

  final _formKey = GlobalKey<FormState>();

  String _profile = 'STUDENT';
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _birthdate = TextEditingController();
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _zipCode = TextEditingController();
  final _city = TextEditingController();
  final _pickupLocation = TextEditingController();
  final _licensePlate = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _busy = false;
  String? _otpMessage;

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
      _pickupLocation,
      _licensePlate,
      _password,
      _password2,
      _otp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _payload() => {
    'profile': _profile,
    'email': _email.text.trim().toLowerCase(),
    'password': _password.text,
    'firstName': _firstName.text.trim(),
    'lastName': _lastName.text.trim(),
    'birthdate': _birthdate.text.trim(),
    'phone': _phone.text.trim(),
    'street': _street.text.trim(),
    'houseNumber': _houseNumber.text.trim(),
    'zipCode': _zipCode.text.trim(),
    'city': _city.text.trim(),
    if (_pickupLocation.text.trim().isNotEmpty)
      'pickupLocation': _pickupLocation.text.trim(),
    if (_licensePlate.text.trim().isNotEmpty)
      'licensePlate': _licensePlate.text.trim(),
    if (_otp.text.trim().isNotEmpty) 'otp': _otp.text.trim(),
  };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .register(payload: _payload());
      if (!mounted) return;
      if (result.completed) {
        // Redirected by the router.
        return;
      }
      final wantsOtp = result.message.toLowerCase().contains('otp');
      setState(() {
        _otpSent = wantsOtp || _otpSent;
        _otpMessage = wantsOtp ? result.message : null;
      });
      if (!wantsOtp) showAppSnack(context, result.message, error: true);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.validationMessage, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Registreren is mislukt.', error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Verplicht veld' : null;

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      locale: const Locale('nl'),
    );
    if (picked == null) return;
    setState(() => _birthdate.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registreren')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Accounttype',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'STUDENT',
                          label: Text('Leerling'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: 'INSTRUCTOR',
                          label: Text('Instructeur'),
                          icon: Icon(Icons.directions_car_outlined),
                        ),
                      ],
                      selected: {_profile},
                      onSelectionChanged: (v) =>
                          setState(() => _profile = v.first),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Persoonlijke gegevens',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Voornaam',
                            ),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Achternaam',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mailadres',
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Verplicht veld';
                        if (!value.contains('@')) {
                          return 'Vul een geldig e-mailadres in';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Telefoonnummer',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthdate,
                      readOnly: true,
                      onTap: _pickBirthdate,
                      decoration: const InputDecoration(
                        labelText: 'Geboortedatum',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                        hintText: 'jjjj-mm-dd',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Verplicht veld'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Adres',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _street,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Straat',
                            ),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _houseNumber,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Huisnr.',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _zipCode,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Postcode',
                            ),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _city,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Plaats',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Lesdetails (optioneel)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pickupLocation,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ophaallocatie',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licensePlate,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Kenteken (bij eigen voertuig)',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Wachtwoord',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Wachtwoord',
                        helperText: _passwordRules,
                        helperMaxLines: 2,
                      ),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.length < 8) {
                          return 'Minimaal 8 tekens';
                        }
                        if (!value.contains(RegExp(r'[a-z]')) ||
                            !value.contains(RegExp(r'[A-Z]')) ||
                            !value.contains(RegExp(r'\d'))) {
                          return 'Gebruik een kleine letter, hoofdletter en cijfer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password2,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Herhaal wachtwoord',
                      ),
                      validator: (v) => v != _password.text
                          ? 'Wachtwoorden komen niet overeen'
                          : null,
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Bevestigingscode',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _otpMessage ??
                            'We hebben een code naar je e-mailadres gestuurd.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Code uit e-mail',
                          counterText: '',
                        ),
                        validator: (v) =>
                            _otpSent && (v == null || v.trim().length < 4)
                            ? 'Vul de 4-cijferige code in'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(
                              _otpSent ? 'Account aanmaken' : 'Code aanvragen',
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Ik heb al een account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
