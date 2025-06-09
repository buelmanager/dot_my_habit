import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../data/models/habit.dart';
import '../../data/repositories/habit_repository.dart';

/// 홈 화면 상태
class HomeState {
  /// 현재 선택된 날짜
  final DateTime selectedDate;

  /// 현재 선택된 뷰 모드 (0: 일간, 1: 주간, 2: 월간)
  final int selectedViewIndex;

  /// 로딩 상태
  final bool isLoading;

  /// 오류 메시지
  final String? errorMessage;

  /// 습관 목록
  final List<Habit> habits;

  /// 주간 완료율 데이터
  final Map<String, double> weeklyProgress;

  /// 최고 스트릭 습관
  final Habit? topHabit;

  /// 기본 생성자
  const HomeState({
    required this.selectedDate,
    required this.selectedViewIndex,
    required this.isLoading,
    this.errorMessage,
    required this.habits,
    required this.weeklyProgress,
    this.topHabit,
  });

  /// 초기 상태 팩토리 생성자
  factory HomeState.initial() {
    return HomeState(
      selectedDate: DateTime.now(),
      selectedViewIndex: 0,
      isLoading: false,
      habits: [],
      weeklyProgress: {},
    );
  }

  /// 복사 생성자
  HomeState copyWith({
    DateTime? selectedDate,
    int? selectedViewIndex,
    bool? isLoading,
    String? errorMessage,
    List<Habit>? habits,
    Map<String, double>? weeklyProgress,
    Habit? topHabit,
    bool clearError = false,
  }) {
    return HomeState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedViewIndex: selectedViewIndex ?? this.selectedViewIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      habits: habits ?? this.habits,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      topHabit: topHabit ?? this.topHabit,
    );
  }
}

/// 홈 화면 뷰모델
class HomeViewModel extends ChangeNotifier  {
  /// 저장소
  final HabitRepository _habitRepository;

  /// 현재 상태
  HomeState _state = HomeState.initial();
  HomeState get state => _state;

  /// 생성자
  HomeViewModel({
    required HabitRepository habitRepository,
  }) : _habitRepository = habitRepository {
    logger.info('HomeViewModel 생성됨');
    _initialize();
  }

  /// 초기화
  Future<void> _initialize() async {
    logger.debug('HomeViewModel 초기화 시작');
    await _loadData();
    logger.debug('HomeViewModel 초기화 완료');
  }

  /// 상태 업데이트
  void _setState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    logger.debug('데이터 로드 시작: ${_state.selectedDate}');

    // 로딩 상태로 변경
    _setState(_state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      // 1. 선택된 날짜의 습관 목록 가져오기
      final habits = await _habitRepository.getHabitsForDate(_state.selectedDate);

      // 2. 주간 완료율 데이터 가져오기
      final weeklyProgress = await _habitRepository.getWeeklyProgress(_state.selectedDate);

      // 3. 최고 스트릭 습관 가져오기
      final topHabit = await _habitRepository.getTopHabit();

      logger.debug('데이터 로드 완료: ${habits.length}개 습관, ${weeklyProgress.length}개 주간 데이터');

      // 상태 업데이트
      _setState(_state.copyWith(
        isLoading: false,
        habits: habits,
        weeklyProgress: weeklyProgress,
        topHabit: topHabit,
      ));
    } catch (e, stackTrace) {
      logger.error('데이터 로드 실패', error: e, stackTrace: stackTrace);

      // 오류 상태로 변경
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: '데이터를 불러오는 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 날짜 선택 변경
  Future<void> setSelectedDate(DateTime date) async {
    logger.debug('선택 날짜 변경: $date');

    // 날짜가 같으면 무시
    if (_state.selectedDate == date) {
      logger.debug('이미 같은 날짜 선택됨, 무시');
      return;
    }

    // 상태 업데이트
    _setState(_state.copyWith(
      selectedDate: date,
    ));

    // 데이터 다시 로드
    await _loadData();
  }

  /// 뷰 모드 변경
  void setSelectedViewIndex(int index) {
    logger.debug('선택 뷰 모드 변경: $index');

    // 인덱스가 같으면 무시
    if (_state.selectedViewIndex == index) {
      logger.debug('이미 같은 뷰 모드 선택됨, 무시');
      return;
    }

    // 상태 업데이트
    _setState(_state.copyWith(
      selectedViewIndex: index,
    ));
  }

  /// 습관 추가
  Future<void> addHabit(String name) async {
    logger.debug('습관 추가: $name');

    // 로딩 상태로 변경
    _setState(_state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      // 저장소에 습관 추가
      final success = await _habitRepository.addHabit(name);

      if (success) {
        logger.info('습관 추가 성공: $name');

        // 데이터 다시 로드
        await _loadData();
      } else {
        logger.warning('습관 추가 실패: $name');

        // 오류 상태로 변경
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: '습관을 추가하는 중 오류가 발생했습니다.',
        ));
      }
    } catch (e, stackTrace) {
      logger.error('습관 추가 오류', error: e, stackTrace: stackTrace);

      // 오류 상태로 변경
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: '습관을 추가하는 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 습관 삭제
  Future<void> deleteHabit(String habitId) async {
    logger.debug('습관 삭제: $habitId');

    // 로딩 상태로 변경
    _setState(_state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      // 저장소에서 습관 삭제
      final success = await _habitRepository.deleteHabit(habitId);

      if (success) {
        logger.info('습관 삭제 성공: $habitId');

        // 데이터 다시 로드
        await _loadData();
      } else {
        logger.warning('습관 삭제 실패: $habitId');

        // 오류 상태로 변경
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: '습관을 삭제하는 중 오류가 발생했습니다.',
        ));
      }
    } catch (e, stackTrace) {
      logger.error('습관 삭제 오류', error: e, stackTrace: stackTrace);

      // 오류 상태로 변경
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: '습관을 삭제하는 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 습관 이름 변경
  Future<void> updateHabitName(String habitId, String newName) async {
    logger.debug('습관 이름 변경: $habitId, 새 이름: $newName');

    // 로딩 상태로 변경
    _setState(_state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    try {
      // 저장소에서 습관 이름 업데이트
      final success = await _habitRepository.updateHabitName(habitId, newName);

      if (success) {
        logger.info('습관 이름 변경 성공: $habitId');

        // 데이터 다시 로드
        await _loadData();
      } else {
        logger.warning('습관 이름 변경 실패: $habitId');

        // 오류 상태로 변경
        _setState(_state.copyWith(
          isLoading: false,
          errorMessage: '습관 이름을 변경하는 중 오류가 발생했습니다.',
        ));
      }
    } catch (e, stackTrace) {
      logger.error('습관 이름 변경 오류', error: e, stackTrace: stackTrace);

      // 오류 상태로 변경
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: '습관 이름을 변경하는 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 습관 완료 상태 토글
  Future<void> toggleHabit(Habit habit) async {
    final habitId = habit.id;
    final newCompletedState = !habit.isCompleted;

    logger.debug('습관 토글: $habitId, 새 상태: ${newCompletedState ? '완료' : '미완료'}');

    try {
      // 로컬 상태 즉시 업데이트 (낙관적 업데이트)
      final updatedHabits = List<Habit>.from(_state.habits);
      final index = updatedHabits.indexWhere((h) => h.id == habitId);

      if (index != -1) {
        updatedHabits[index] = habit.copyWith(
          isCompleted: newCompletedState,
          completedAt: newCompletedState ? DateTime.now() : null,
        );

        _setState(_state.copyWith(
          habits: updatedHabits,
          clearError: true,
        ));
      }

      // 저장소에서 습관 토글
      final success = await _habitRepository.toggleHabit(
        habitId,
        _state.selectedDate,
        newCompletedState,
      );

      if (success) {
        logger.info('습관 토글 성공: $habitId');

        // 데이터 다시 로드 (스트릭 업데이트 등을 위해)
        await _loadData();
      } else {
        logger.warning('습관 토글 실패: $habitId');

        // 실패 시 원래 상태로 복원
        await _loadData();
      }
    } catch (e, stackTrace) {
      logger.error('습관 토글 오류', error: e, stackTrace: stackTrace);

      // 오류 상태로 변경하고 원래 상태로 복원
      _setState(_state.copyWith(
        errorMessage: '습관 상태를 변경하는 중 오류가 발생했습니다: ${e.toString()}',
      ));

      // 데이터 다시 로드 (원래 상태로 복원)
      await _loadData();
    }
  }

  /// 이전 날짜로 이동
  Future<void> goToPreviousDate() async {
    final previousDate = _state.selectedDate.subtract(const Duration(days: 1));
    await setSelectedDate(previousDate);
  }

  /// 다음 날짜로 이동
  Future<void> goToNextDate() async {
    final nextDate = _state.selectedDate.add(const Duration(days: 1));
    await setSelectedDate(nextDate);
  }

  /// 오늘 날짜로 이동
  Future<void> goToToday() async {
    await setSelectedDate(DateTime.now());
  }

  /// 새로고침
  Future<void> refresh() async {
    logger.debug('데이터 새로고침');
    await _loadData();
  }
}