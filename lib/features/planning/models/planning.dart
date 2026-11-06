import '../../../core/utils/formatters.dart';
import '../../auth/models/user.dart';
import '../../orders/models/order.dart';

/// A booked lesson slot (`order_planning` row).
class Planning {
  const Planning({
    required this.id,
    this.orderItemId,
    this.startDate,
    this.endDate,
    this.status = 'pending',
    this.instructorId,
    this.notes,
    this.cancelReason,
    this.studentConfirmation,
    this.order,
    this.drivingClass,
    this.orderItem,
    this.payment,
    this.student,
    this.instructor,
    this.logs = const [],
  });

  factory Planning.fromJson(Map<String, dynamic> json) => Planning(
    id: int.tryParse(json['id'].toString()) ?? 0,
    orderItemId: int.tryParse(json['orderItemId'].toString()),
    startDate: F.date(json['startDate']?.toString()),
    endDate: F.date(json['endDate']?.toString()),
    status: json['status']?.toString() ?? 'pending',
    instructorId: int.tryParse(json['instructorId'].toString()),
    notes: json['notes']?.toString(),
    cancelReason: json['cancelReason']?.toString(),
    studentConfirmation: json['studentConfirmation'] is bool
        ? json['studentConfirmation'] as bool
        : null,
    order: json['order'] is Map
        ? Order.fromJson(json['order'] as Map<String, dynamic>)
        : null,
    drivingClass: json['drivingClass'] is Map
        ? DrivingClass.fromJson(json['drivingClass'] as Map<String, dynamic>)
        : null,
    orderItem: json['orderItem'] is Map
        ? OrderItem.fromJson(json['orderItem'] as Map<String, dynamic>)
        : null,
    payment: json['payment'] is Map
        ? Payment.fromJson(json['payment'] as Map<String, dynamic>)
        : null,
    student: json['student'] is Map
        ? User.fromJson(json['student'] as Map<String, dynamic>)
        : null,
    instructor: json['instructor'] is Map
        ? User.fromJson(json['instructor'] as Map<String, dynamic>)
        : null,
    logs: json['logs'] is List
        ? (json['logs'] as List)
              .whereType<Map>()
              .map((e) => PlanningLog.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );

  final int id;
  final int? orderItemId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int? instructorId;
  final String? notes;
  final String? cancelReason;
  final bool? studentConfirmation;
  final Order? order;
  final DrivingClass? drivingClass;
  final OrderItem? orderItem;
  final Payment? payment;
  final User? student;
  final User? instructor;
  final List<PlanningLog> logs;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPast => endDate != null && endDate!.isBefore(DateTime.now());

  int get durationMinutes {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inMinutes;
  }

  String get statusLabel => switch (status) {
    'confirmed' => 'Bevestigd',
    'completed' => 'Afgerond',
    'cancelled' => 'Geannuleerd',
    _ => 'In afwachting',
  };
}

class PlanningLog {
  const PlanningLog({this.id, this.action, this.createdAt, this.user});

  factory PlanningLog.fromJson(Map<String, dynamic> json) => PlanningLog(
    id: int.tryParse(json['id'].toString()),
    action: json['action']?.toString(),
    createdAt: F.date(json['createdAt']?.toString()),
    user: json['user'] is Map
        ? User.fromJson(json['user'] as Map<String, dynamic>)
        : null,
  );

  final int? id;
  final String? action;
  final DateTime? createdAt;
  final User? user;
}

/// A question + answer pair of a lesson card.
class LessonCardQuestion {
  const LessonCardQuestion({
    required this.id,
    this.name,
    this.text,
    this.score,
    this.category,
    this.subCategory,
  });

  factory LessonCardQuestion.fromJson(Map<String, dynamic> json) =>
      LessonCardQuestion(
        id: int.tryParse(json['id'].toString()) ?? 0,
        name: json['name']?.toString(),
        text: json['text']?.toString(),
        score: int.tryParse(json['score'].toString()),
        category: json['category'] is Map
            ? LessonCardCategory.fromJson(
                json['category'] as Map<String, dynamic>,
              )
            : null,
        subCategory: json['subCategory'] is Map
            ? LessonCardCategory.fromJson(
                json['subCategory'] as Map<String, dynamic>,
              )
            : null,
      );

  final int id;
  final String? name;
  final String? text;
  final int? score;
  final LessonCardCategory? category;
  final LessonCardCategory? subCategory;

  String get title => name ?? subCategory?.name ?? 'Vraag $id';
}

class LessonCardCategory {
  const LessonCardCategory({this.id, this.name, this.type});

  factory LessonCardCategory.fromJson(Map<String, dynamic> json) =>
      LessonCardCategory(
        id: int.tryParse(json['id'].toString()),
        name: json['name']?.toString(),
        type: json['type']?.toString(),
      );

  final int? id;
  final String? name;
  final String? type;
}
