import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
// XFile 클래스를 사용하기 위한 import
import 'package:cross_file/cross_file.dart';

import '../../core/logger.dart';
import '../dtos/habit_dto.dart';
import '../repositories/habit_repository.dart';

/// 습관 데이터 백업 및 복원 서비스
class BackupService {
  static const String _tag = 'BackupService';
  final HabitRepository _habitRepository;

  BackupService({required HabitRepository habitRepository})
      : _habitRepository = habitRepository;

  /// 습관 데이터를 JSON 파일로 내보내기
  Future<bool> exportToJson() async {
    try {
      logger.debug('습관 데이터 JSON 내보내기 시작', tag: _tag);

      // 권한 요청
      if (!await _requestStoragePermission()) {
        logger.warning('저장소 권한 없음', tag: _tag);
        return false;
      }

      // 모든 습관 데이터 가져오기
      final habits = await _habitRepository.exportAllHabits();
      if (habits.isEmpty) {
        logger.warning('내보낼 습관 데이터가 없음', tag: _tag);
        return false;
      }

      // JSON으로 변환
      final List<Map<String, dynamic>> jsonList = habits.map((h) => h.toJson()).toList();
      final jsonString = jsonEncode({
        'habits': jsonList,
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0',
      });

      // 파일 저장
      final fileName = 'dot_habits_${DateTime.now().millisecondsSinceEpoch}.json';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // 공유 다이얼로그 표시
      // Share.shareFiles API 대신 XFile 사용하여 공유
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        text: '점(Dot) 습관 데이터 백업',
      );

      logger.info('습관 데이터 내보내기 성공: $filePath', tag: _tag);
      return true;
    } catch (e, stackTrace) {
      logger.error('습관 데이터 내보내기 실패: ${e.toString()}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// JSON 파일에서 습관 데이터 가져오기
  Future<bool> importFromJson() async {
    try {
      logger.debug('습관 데이터 JSON 가져오기 시작', tag: _tag);

      // 권한 요청
      if (!await _requestStoragePermission()) {
        logger.warning('저장소 권한 없음', tag: _tag);
        return false;
      }

      // 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        logger.warning('파일 선택 취소됨', tag: _tag);
        return false;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (!jsonData.containsKey('habits') || jsonData['habits'] is! List) {
        logger.warning('유효하지 않은 백업 파일 형식', tag: _tag);
        return false;
      }

      // HabitDto 리스트로 변환
      final habitsJson = jsonData['habits'] as List;
      final habits = habitsJson
          .map((h) => HabitDto.fromJson(h as Map<String, dynamic>))
          .toList();

      // 습관 데이터 가져오기
      final success = await _habitRepository.importHabits(habits);

      logger.info('습관 데이터 가져오기 ${success ? '성공' : '실패'}: ${habits.length}개', tag: _tag);
      return success;
    } catch (e, stackTrace) {
      logger.error('습관 데이터 가져오기 실패: ${e.toString()}', tag: _tag, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 저장소 권한 요청
  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }
}