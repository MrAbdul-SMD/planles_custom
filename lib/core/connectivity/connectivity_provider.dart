import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device reports any network interface other than none.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  Future<bool> hasConnection(List<ConnectivityResult> results) async {
    return results.any((r) => r != ConnectivityResult.none);
  }

  final controller = StreamController<bool>();

  connectivity.checkConnectivity().then((results) async {
    controller.add(await hasConnection(results));
  });

  final sub = connectivity.onConnectivityChanged.listen((results) async {
    controller.add(await hasConnection(results));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStatusProvider);
  return async.maybeWhen(data: (v) => v, orElse: () => true);
});
