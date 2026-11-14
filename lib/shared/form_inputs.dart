import 'package:formz/formz.dart';

enum EmailValidationError { empty, invalid }

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure([super.value = '']) : super.pure();
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  EmailValidationError? validator(String value) {
    final v = value.trim();
    if (v.isEmpty) return EmailValidationError.empty;
    if (!_emailRegex.hasMatch(v)) return EmailValidationError.invalid;
    return null;
  }
}

enum PasswordValidationError { empty, tooShort }

class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure([super.value = '']) : super.pure();
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 6) return PasswordValidationError.tooShort;
    return null;
  }
}

enum RequiredFieldValidationError { empty }

class RequiredFieldInput
    extends FormzInput<String, RequiredFieldValidationError> {
  const RequiredFieldInput.pure([super.value = '']) : super.pure();
  const RequiredFieldInput.dirty([super.value = '']) : super.dirty();

  @override
  RequiredFieldValidationError? validator(String value) {
    if (value.trim().isEmpty) return RequiredFieldValidationError.empty;
    return null;
  }
}
