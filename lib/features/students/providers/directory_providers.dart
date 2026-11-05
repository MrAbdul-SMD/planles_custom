import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/models/user.dart';
import '../data/directory_repository.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>(
  (ref) => DirectoryRepository(ref.watch(apiClientProvider)),
);

/// Students assigned to the signed-in instructor.
final myStudentsProvider = FutureProvider<List<User>>((ref) {
  return ref.watch(directoryRepositoryProvider).myStudents();
});
