import '../../../core/utils/formatters.dart';

/// The Planles user. Returned by `/auth/me`, embedded in plannings, orders,
/// students and instructors.
class User {
  const User({
    required this.id,
    this.profile = 'STUDENT',
    this.email,
    this.firstName,
    this.lastName,
    this.name,
    this.gender,
    this.birthdate,
    this.phone,
    this.street,
    this.houseNumber,
    this.zipCode,
    this.city,
    this.pickupLocation,
    this.licensePlate,
    this.carImage,
    this.carImageUrl,
    this.balance,
    this.instructorId,
    this.active = true,
    this.createdAt,
    this.guardian,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: _asInt(json['id']) ?? 0,
    profile: json['profile']?.toString() ?? 'STUDENT',
    email: json['email']?.toString(),
    firstName: json['firstName']?.toString(),
    lastName: json['lastName']?.toString(),
    name: json['name']?.toString(),
    gender: json['gender']?.toString(),
    birthdate: json['birthdate']?.toString(),
    phone: json['phone']?.toString(),
    street: json['street']?.toString(),
    houseNumber: json['houseNumber']?.toString(),
    zipCode: json['zipCode']?.toString(),
    city: json['city']?.toString(),
    pickupLocation: json['pickupLocation']?.toString(),
    licensePlate: json['licensePlate']?.toString(),
    carImage: json['carImage']?.toString(),
    carImageUrl: json['carImageUrl']?.toString(),
    balance: F.toDouble(json['balance']?.toString()),
    instructorId: _asInt(json['instructorId']),
    active: json['active'] as bool? ?? true,
    createdAt: F.date(json['createdAt']?.toString()),
    guardian: json['guardian'] is Map
        ? Guardian.fromJson(json['guardian'] as Map<String, dynamic>)
        : null,
  );

  final int id;
  final String profile;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? gender;
  final String? birthdate;
  final String? phone;
  final String? street;
  final String? houseNumber;
  final String? zipCode;
  final String? city;
  final String? pickupLocation;
  final String? licensePlate;
  final String? carImage;
  final String? carImageUrl;
  final double? balance;
  final int? instructorId;
  final bool active;
  final DateTime? createdAt;
  final Guardian? guardian;

  bool get isInstructor => profile == 'INSTRUCTOR';
  bool get isAdmin => profile == 'ADMIN';

  String get fullName {
    final parts = [firstName, lastName].where((e) => e != null && e.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    if (name != null && name!.isNotEmpty) return name!;
    return email ?? 'Geen naam';
  }

  String get initials {
    final f = firstName?.trim();
    final l = lastName?.trim();
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) {
      final mail = email ?? '?';
      return mail.isEmpty ? '?' : mail.substring(0, 1).toUpperCase();
    }
    final a = (f != null && f.isNotEmpty) ? f.substring(0, 1) : '';
    final b = (l != null && l.isNotEmpty) ? l.substring(0, 1) : '';
    return '$a$b'.toUpperCase();
  }

  User copyWith({double? balance, String? carImageUrl, String? profile}) =>
      User(
        id: id,
        profile: profile ?? this.profile,
        email: email,
        firstName: firstName,
        lastName: lastName,
        name: name,
        gender: gender,
        birthdate: birthdate,
        phone: phone,
        street: street,
        houseNumber: houseNumber,
        zipCode: zipCode,
        city: city,
        pickupLocation: pickupLocation,
        licensePlate: licensePlate,
        carImage: carImage,
        carImageUrl: carImageUrl ?? this.carImageUrl,
        balance: balance ?? this.balance,
        instructorId: instructorId,
        active: active,
        createdAt: createdAt,
        guardian: guardian,
      );

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class Guardian {
  const Guardian({
    this.type,
    this.lastName,
    this.firstName,
    this.email,
    this.phone,
    this.street,
    this.houseNumber,
    this.zipCode,
    this.city,
    this.companyName,
    this.vatNumber,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) => Guardian(
    type: json['type']?.toString(),
    lastName: json['lastName']?.toString(),
    firstName: json['firstName']?.toString(),
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
    street: json['street']?.toString(),
    houseNumber: json['houseNumber']?.toString(),
    zipCode: json['zipCode']?.toString(),
    city: json['city']?.toString(),
    companyName: json['companyName']?.toString(),
    vatNumber: json['vatNumber']?.toString(),
  );

  final String? type;
  final String? lastName;
  final String? firstName;
  final String? email;
  final String? phone;
  final String? street;
  final String? houseNumber;
  final String? zipCode;
  final String? city;
  final String? companyName;
  final String? vatNumber;

  Map<String, dynamic> toJson() => {
    if (type != null) 'type': type,
    if (lastName != null) 'lastName': lastName,
    if (firstName != null) 'firstName': firstName,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (street != null) 'street': street,
    if (houseNumber != null) 'houseNumber': houseNumber,
    if (zipCode != null) 'zipCode': zipCode,
    if (city != null) 'city': city,
    if (companyName != null) 'companyName': companyName,
    if (vatNumber != null) 'vatNumber': vatNumber,
  };
}
