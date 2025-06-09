import 'package:dot_my_habit/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasources/local/dao/habit_dao.dart';
import 'data/repositories/habit_repository.dart';
import 'data/services/backup_service.dart';

/// HabitDao 프로바이더
final habitDaoProvider = Provider<HabitDao>((ref) {
  return HabitDao();
});

/// 습관 저장소 프로바이더
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final habitDao = ref.watch(habitDaoProvider);

  return HabitRepositoryImpl(localDataSource: habitDao);
});

/// 백업 서비스 프로바이더
final backupServiceProvider = Provider<BackupService>((ref) {
  final habitRepository = ref.watch(habitRepositoryProvider);
  return BackupService(habitRepository: habitRepository);
});

/// 홈 뷰모델 프로바이더
final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  final habitRepository = ref.watch(habitRepositoryProvider);
  return HomeViewModel(habitRepository: habitRepository);
});
