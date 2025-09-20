import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/services/home_repository.dart';

final homeRepoProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});
