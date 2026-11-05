import '../../../core/utils/formatters.dart';
import '../../auth/models/user.dart';

/// Catalog: a vehicle type (`Personenauto`, `Motor`, ...).
class Vehicle {
  const Vehicle({required this.id, this.name, this.code});

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name']?.toString(),
        code: json['code']?.toString(),
      );

  final int id;
  final String? name;
  final String? code;
}

/// A purchasable driving class (`Proefles`, `10 lessen`, ...).
class DrivingClass {
  const DrivingClass({
    required this.id,
    this.vehicleTypeId,
    this.lessonType,
    this.name,
    this.duration,
    this.price,
  });

  factory DrivingClass.fromJson(Map<String, dynamic> json) => DrivingClass(
        id: int.tryParse(json['id'].toString()) ?? 0,
        vehicleTypeId: int.tryParse(json['vehicleTypeId'].toString()),
        lessonType: json['lessonType']?.toString(),
        name: json['name']?.toString(),
        duration: json['duration']?.toString(),
        price: json['price']?.toString(),
      );

  final int id;
  final int? vehicleTypeId;
  final String? lessonType;
  final String? name;
  final String? duration;
  final String? price;

  double? get priceValue => F.toDouble(price);
  int? get durationMinutes => F.durationMinutes(duration);

  bool get isTrial => lessonType == 'trial';
}

/// Mollie payment attached to an order.
class Payment {
  const Payment({
    this.id,
    this.orderId,
    this.paymentId,
    this.type,
    this.status,
    this.amount,
    this.discount,
    this.finalAmount,
    this.checkoutUrl,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: int.tryParse(json['id'].toString()),
        orderId: int.tryParse(json['orderId'].toString()),
        paymentId: json['paymentId']?.toString(),
        type: json['type']?.toString(),
        status: json['status']?.toString(),
        amount: json['amount']?.toString(),
        discount: json['discount']?.toString(),
        finalAmount: json['finalAmount']?.toString(),
        checkoutUrl: json['checkoutUrl']?.toString(),
        paidAt: F.date(json['paidAt']?.toString()),
      );

  final int? id;
  final int? orderId;
  final String? paymentId;
  final String? type;
  final String? status;
  final String? amount;
  final String? discount;
  final String? finalAmount;
  final String? checkoutUrl;
  final DateTime? paidAt;

  double? get amountValue => F.toDouble(amount);
  double? get finalAmountValue => F.toDouble(finalAmount);
  bool get isPaid => status == 'paid';
}

class OrderItem {
  const OrderItem({
    required this.id,
    this.orderId,
    this.drivingClassId,
    this.quantity,
    this.drivingClass,
    this.totalDuration,
    this.reservedDuration,
    this.availableDuration,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: int.tryParse(json['id'].toString()) ?? 0,
        orderId: int.tryParse(json['orderId'].toString()),
        drivingClassId: int.tryParse(json['drivingClassId'].toString()),
        quantity: int.tryParse(json['quantity'].toString()),
        drivingClass: json['drivingClass'] is Map
            ? DrivingClass.fromJson(json['drivingClass'] as Map<String, dynamic>)
            : null,
        totalDuration: int.tryParse(json['totalDuration'].toString()),
        reservedDuration: int.tryParse(json['reservedDuration'].toString()),
        availableDuration: int.tryParse(json['availableDuration'].toString()),
      );

  final int id;
  final int? orderId;
  final int? drivingClassId;
  final int? quantity;
  final DrivingClass? drivingClass;

  /// Minutes.
  final int? totalDuration;
  final int? reservedDuration;
  final int? availableDuration;

  int get remainingLessons {
    final q = quantity ?? 0;
    final reserved = (reservedDuration ?? 0) == 0 || (drivingClass?.durationMinutes ?? 0) == 0
        ? 0
        : (reservedDuration! / drivingClass!.durationMinutes!).round();
    return q - reserved;
  }
}

class Order {
  const Order({
    required this.id,
    required this.studentId,
    this.instructorId,
    this.data,
    this.createdAt,
    this.payment,
    this.student,
    this.instructor,
    this.totalDuration,
    this.reservedDuration,
    this.availableDuration,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: int.tryParse(json['id'].toString()) ?? 0,
        studentId: int.tryParse(json['studentId'].toString()) ?? 0,
        instructorId: int.tryParse(json['instructorId'].toString()),
        data: json['data'] is Map ? json['data'] as Map<String, dynamic> : null,
        createdAt: F.date(json['createdAt']?.toString()),
        payment: json['payment'] is Map
            ? Payment.fromJson(json['payment'] as Map<String, dynamic>)
            : null,
        student: json['student'] is Map
            ? User.fromJson(json['student'] as Map<String, dynamic>)
            : null,
        instructor: json['instructor'] is Map
            ? User.fromJson(json['instructor'] as Map<String, dynamic>)
            : null,
        totalDuration: int.tryParse(json['totalDuration'].toString()),
        reservedDuration: int.tryParse(json['reservedDuration'].toString()),
        availableDuration: int.tryParse(json['availableDuration'].toString()),
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map>()
                .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : null,
      );

  final int id;
  final int studentId;
  final int? instructorId;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final Payment? payment;
  final User? student;
  final User? instructor;
  final int? totalDuration;
  final int? reservedDuration;
  final int? availableDuration;
  final List<OrderItem>? items;

  bool get isPaid => payment?.isPaid ?? false;
}
