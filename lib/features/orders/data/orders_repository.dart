import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/order.dart';

/// Catalog + order endpoints (`/vehicle`, `/class`, `/order`, `/balance`).
class OrdersRepository {
  OrdersRepository(this._api);

  final ApiClient _api;

  // --------------------------------------------------------------- catalog

  Future<List<Vehicle>> vehicles() async {
    final data = await _api.get('/vehicle');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Vehicle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<DrivingClass>> classes(int vehicleTypeId) async {
    final data = await _api.get('/class/vehicle/$vehicleTypeId');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => DrivingClass.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------------------------------------------------------------- orders

  Future<({int total, List<Order> items})> getAll({
    int pageIndex = 0,
    int pageSize = 20,
  }) async {
    final data = await _api.get(
      '/order',
      query: {'pageIndex': pageIndex, 'pageSize': pageSize},
    );
    if (data is! Map) return (total: 0, items: const <Order>[]);
    final raw = data['result'];
    return (
      total: int.tryParse(data['total'].toString()) ?? 0,
      items: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const <Order>[],
    );
  }

  Future<Order> getById(int id) async {
    final data = await _api.get('/order/$id');
    if (data is! Map) {
      throw const ApiException(
        'Bestelling niet gevonden.',
        code: AppErrorCode.orderNotFound,
      );
    }
    return Order.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<OrderItem>> items(int orderId) async {
    final data = await _api.get('/order/$orderId/items');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<({String? checkoutUrl, int? orderId})> create({
    required String paymentType,
    required List<({int id, int quantity})> items,
    List<({int itemId, DateTime start, DateTime end})>? planning,
    int? studentId,
    String? redirectUrl,
  }) async {
    final data = await _api.post(
      '/order',
      body: {
        'paymentType': paymentType,
        'items': items
            .map((e) => {'id': e.id, 'quantity': e.quantity})
            .toList(),
        if (planning != null && planning.isNotEmpty)
          'planning': planning
              .map(
                (e) => {
                  'itemId': e.itemId,
                  'startDate': e.start.toUtc().toIso8601String(),
                  'endDate': e.end.toUtc().toIso8601String(),
                },
              )
              .toList(),
        'studentId': ?studentId,
        'redirectUrl': ?redirectUrl,
      },
    );
    if (data is! Map) return (checkoutUrl: null, orderId: null);
    return (
      checkoutUrl: data['checkoutUrl']?.toString(),
      orderId: int.tryParse(data['orderId'].toString()),
    );
  }

  Future<String?> pay({
    required int orderId,
    int? discount,
    String? redirectUrl,
  }) async {
    final data = await _api.post(
      '/order/$orderId/pay',
      body: {'discount': ?discount, 'redirectUrl': ?redirectUrl},
    );
    return data is Map ? data['checkoutUrl']?.toString() : null;
  }

  Future<void> requestPayment(int orderId) =>
      _api.post('/order/$orderId/request-payment');

  // --------------------------------------------------------------- balance

  /// Returns the Mollie checkout URL for topping up the balance.
  Future<String> purchaseBalance({
    required num amount,
    String? redirectUrl,
  }) async {
    final data = await _api.post(
      '/balance',
      body: {'amount': amount, 'redirectUrl': ?redirectUrl},
    );
    final url = data is Map ? data['checkoutUrl']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw const ApiException(
        'Het openen van de betaling is mislukt.',
        code: AppErrorCode.paymentFailed,
      );
    }
    return url;
  }

  // -------------------------------------------------------------- invoice

  /// Presigned-free: the API returns the PDF bytes directly.
  Future<List<int>> invoice(int orderId) =>
      _api.getBytes('/invoice/order/$orderId');
}
