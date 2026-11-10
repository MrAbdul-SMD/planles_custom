import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets.dart';
import '../providers/auth_provider.dart';

import 'package:image_picker/image_picker.dart';

/// Registration is a two-step OTP flow: fill in the form → the API mails a
/// code → enter the code → the account is created and we are signed in.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
  File? _carImage;

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
    if (_carImage != null) 'carImage': _carImage!.path,
  };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .register(payload: _payload(), carImage: _carImage);
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
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, describeError(context, e), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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

  Future<void> _pickCarImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (picked != null) {
      setState(() => _carImage = File(picked.path));
    }
  }

  void _clearCarImage() {
    setState(() => _carImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    String? requiredValidator(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.registerRequired : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerTitle),
      ),
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
                      l10n.registerAccountType,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'STUDENT',
                          label: Text(l10n.registerStudent),
                          icon: const Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: 'INSTRUCTOR',
                          label: Text(l10n.registerInstructor),
                          icon: const Icon(Icons.directions_car_outlined),
                        ),
                      ],
                      selected: {_profile},
                      onSelectionChanged: (v) =>
                          setState(() => _profile = v.first),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      l10n.registerPersonalDetails,
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
                            decoration: InputDecoration(
                              labelText: l10n.registerFirstName,
                            ),
                            validator: requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.registerLastName,
                            ),
                            validator: requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.loginEmailLabel,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.registerRequired;
                        if (!value.contains('@')) {
                          return l10n.loginEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.registerPhone,
                      ),
                      validator: requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthdate,
                      readOnly: true,
                      onTap: _pickBirthdate,
                      decoration: InputDecoration(
                        labelText: l10n.registerBirthdate,
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        hintText: l10n.registerBirthdateHint,
                      ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _street,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.registerStreet,
                            ),
                            validator: requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _houseNumber,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.registerHouseNumber,
                            ),
                            validator: requiredValidator,
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
                            decoration: InputDecoration(
                              labelText: l10n.registerZipCode,
                            ),
                            validator: requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _city,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.registerCity,
                            ),
                            validator: requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      l10n.registerLessonDetails,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pickupLocation,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.registerPickupLocation,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licensePlate,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.registerLicensePlate,
                      ),
                    ),
                    if (_profile == 'INSTRUCTOR') ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.registerCarImage,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _carImage == null
                                ? ElevatedButton.icon(
                                    onPressed: _pickCarImage,
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: Text(l10n.registerCarImageSelect),
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.check_circle_outlined,
                                          color: Colors.green, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Car image selected',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _carImage != null
                                ? _clearCarImage
                                : null,
                            icon: const Icon(Icons.clear_outlined),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      l10n.registerPasswordLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.registerPasswordLabel,
                        helperText: l10n.registerPasswordRules,
                        helperMaxLines: 2,
                      ),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.length < 8) {
                          return l10n.registerPasswordMin8;
                        }
                        if (!value.contains(RegExp(r'[a-z]')) ||
                            !value.contains(RegExp(r'[A-Z]')) ||
                            !value.contains(RegExp(r'\d'))) {
                          return l10n.registerPasswordNeedsMix;
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
                      decoration: InputDecoration(
                        labelText: l10n.registerPasswordRepeat,
                      ),
                      validator: (v) => v != _password.text
                          ? l10n.registerPasswordMismatch
                          : null,
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.registerOtpTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _otpMessage ?? l10n.registerOtpFallback,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: l10n.registerOtpLabel,
                          counterText: '',
                        ),
                        validator: (v) =>
                            _otpSent && (v == null || v.trim().length < 4)
                            ? l10n.registerOtpRequired
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
                              _otpSent
                                  ? l10n.registerSubmitCreate
                                  : l10n.registerSubmitCode,
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.registerHaveAccount),
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
