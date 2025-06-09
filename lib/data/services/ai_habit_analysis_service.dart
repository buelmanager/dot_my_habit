// lib/data/services/ai_habit_analysis_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../../core/logger.dart';
import '../models/habit.dart';

/// AI를 활용한 습관 분석 서비스
class AIHabitAnalysisService {
  static const String _tag = 'AIHabitAnalysisService';

  // 싱글톤 패턴
  static final AIHabitAnalysisService _instance =
      AIHabitAnalysisService._internal();
  factory AIHabitAnalysisService() => _instance;
  AIHabitAnalysisService._internal();

  // API 키 가져오기
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // 모델 인스턴스 - 중복 초기화 방지를 위해 nullable로 변경
  GenerativeModel? _model;

  // 초기화 상태
  bool _isInitialized = false;
  String? _initializationError;

  /// 초기화 메서드
  Future<void> initialize() async {
    // 이미 초기화된 경우 중복 실행 방지
    if (_isInitialized && _model != null) {
      logger.info('✅ AI 서비스가 이미 초기화되어 있습니다', tag: _tag);
      return;
    }

    try {
      logger.info('🚀 AI 습관 분석 서비스 초기화 시작', tag: _tag);

      // API 키 검증
      if (apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY가 설정되지 않았습니다');
      }

      if (apiKey == 'your_gemini_api_key_here') {
        throw Exception('GEMINI_API_KEY가 기본값으로 설정되어 있습니다. 실제 API 키로 변경해주세요');
      }

      logger.debug('🔑 API 키 확인됨: ${apiKey.substring(0, 10)}...', tag: _tag);

      // 모델 인스턴스가 이미 있다면 재사용
      if (_model == null) {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash', // 더 저렴한 모델 사용
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.3, // 낮은 온도로 비용 절약
            topK: 20, // 더 제한적인 토큰 선택
            topP: 0.8,
            maxOutputTokens: 1024, // 토큰 수 제한으로 비용 절약
          ),
        );
        logger.debug('🤖 AI 모델 인스턴스 생성 완료 (Gemini 1.5 Flash)', tag: _tag);
      } else {
        logger.debug('♻️ 기존 AI 모델 인스턴스 재사용', tag: _tag);
      }

      // 연결 테스트 생략 - API 할당량 절약
      logger.debug('⚡ 연결 테스트 생략 (할당량 절약)', tag: _tag);

      _isInitialized = true;
      _initializationError = null;
      logger.info('🎉 AI 습관 분석 서비스가 성공적으로 초기화되었습니다.', tag: _tag);
    } catch (e, stackTrace) {
      _isInitialized = false;
      _initializationError = e.toString();
      logger.error(
        '❌ AI 습관 분석 서비스 초기화 실패: $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      // 할당량 초과 에러인 경우 특별 처리
      if (e.toString().contains('quota') || e.toString().contains('exceeded')) {
        logger.warning('📊 API 할당량 초과로 인한 실패 - 폴백 모드로 전환', tag: _tag);
        _isInitialized = false; // 폴백 응답 사용하도록 설정
        return; // rethrow 하지 않고 조용히 실패
      }

      rethrow;
    }
  }

  /// 서비스 재설정 (디버깅용)
  void reset() {
    logger.warning('🔄 AI 서비스 재설정 수행', tag: _tag);
    _model = null;
    _isInitialized = false;
    _initializationError = null;
  }

  /// 초기화 상태 확인
  bool get isInitialized => _isInitialized;
  String? get initializationError => _initializationError;

  /// 안전한 모델 접근
  GenerativeModel get _safeModel {
    if (_model == null || !_isInitialized) {
      throw Exception('AI 서비스가 초기화되지 않았습니다. initialize()를 먼저 호출해주세요.');
    }
    return _model!;
  }

  /// 개인화된 습관 인사이트 생성
  Future<Map<String, dynamic>> generatePersonalizedInsights({
    required List<Habit> habits,
    required Map<String, double> weeklyProgress,
    required Map<String, dynamic> monthlyData,
    required int totalCompletedHabits,
    required int totalHabits,
    required int activeDays,
  }) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch;
    logger.info('🧠 AI 개인화 인사이트 생성 시작 (ID: $requestId)', tag: _tag);

    try {
      // 할당량 초과 상황에서는 즉시 폴백 응답 제공
      if (_initializationError != null &&
          (_initializationError!.contains('quota') ||
              _initializationError!.contains('exceeded'))) {
        logger.info('📊 API 할당량 제한으로 폴백 인사이트 제공 (ID: $requestId)', tag: _tag);
        return _getFallbackInsights();
      }

      // 초기화 상태 확인 및 자동 재시도
      if (!_isInitialized || _model == null) {
        logger.warning(
          '⚠️ AI 서비스가 초기화되지 않음. 자동 초기화 시도 (ID: $requestId)',
          tag: _tag,
        );
        await initialize();

        // 초기화 실패 시 폴백 응답
        if (!_isInitialized) {
          logger.info('🔄 초기화 실패로 폴백 인사이트 제공 (ID: $requestId)', tag: _tag);
          return _getFallbackInsights();
        }
      }

      // 입력 데이터 로그
      logger.debug('📊 입력 데이터 (ID: $requestId):', tag: _tag);
      logger.debug('  - 습관 수: ${habits.length}', tag: _tag);
      logger.debug('  - 총 완료: $totalCompletedHabits/$totalHabits', tag: _tag);
      logger.debug('  - 활성 일수: $activeDays', tag: _tag);

      final prompt = _buildInsightsPrompt(
        habits: habits,
        weeklyProgress: weeklyProgress,
        monthlyData: monthlyData,
        totalCompletedHabits: totalCompletedHabits,
        totalHabits: totalHabits,
        activeDays: activeDays,
      );
      logger.debug('📝 프롬프트 생성 완료 ${prompt}자, ID: $requestId)', tag: _tag);

      logger.debug(
        '📝 프롬프트 생성 완료 (길이: ${prompt.length}자, ID: $requestId)',
        tag: _tag,
      );
      logger.debug('🔄 AI 모델에 요청 전송 중... (ID: $requestId)', tag: _tag);

      final response = await _safeModel.generateContent([Content.text(prompt)]);
      final aiResponse = response.text ?? '';

      final requestDuration = DateTime.now().difference(startTime);
      logger.info(
        '⚡ AI 응답 수신 완료 (소요시간: ${requestDuration.inMilliseconds}ms, ID: $requestId)',
        tag: _tag,
      );
      logger.debug(
        '📄 AI 응답 길이: ${aiResponse.length}자 (ID: $requestId)',
        tag: _tag,
      );

      final parsedResult = _parseInsightsResponse(aiResponse);

      logger.info('✅ AI 인사이트 생성 완료 (ID: $requestId)', tag: _tag);
      logger.debug(
        '🎯 파싱 결과 키 (ID: $requestId): ${parsedResult.keys.toList()}',
        tag: _tag,
      );

      return parsedResult;
    } catch (e, stackTrace) {
      final errorDuration = DateTime.now().difference(startTime);
      logger.error(
        '❌ AI 인사이트 생성 실패 (소요시간: ${errorDuration.inMilliseconds}ms, ID: $requestId): $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      // 에러 타입별 로그
      if (e.toString().contains('quota') || e.toString().contains('exceeded')) {
        logger.error('📊 API 할당량 초과 오류 (ID: $requestId)', tag: _tag);
        _initializationError = e.toString(); // 향후 요청에서 즉시 폴백 사용
      } else if (e.toString().contains('API_KEY')) {
        logger.error('🔑 API 키 관련 오류 (ID: $requestId)', tag: _tag);
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        logger.error('🌐 네트워크 관련 오류 (ID: $requestId)', tag: _tag);
      }

      logger.info('🔄 폴백 인사이트 반환 (ID: $requestId)', tag: _tag);
      return _getFallbackInsights();
    }
  }

  /// 습관 추천 생성
  Future<List<Map<String, dynamic>>> generateHabitRecommendations({
    required List<Habit> currentHabits,
    required Map<String, double> weeklyProgress,
    required double averageCompletionRate,
  }) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch;
    logger.info('💡 AI 습관 추천 생성 시작 (ID: $requestId)', tag: _tag);

    try {
      // 할당량 초과 상황에서는 즉시 폴백 응답 제공
      if (_initializationError != null &&
          (_initializationError!.contains('quota') ||
              _initializationError!.contains('exceeded'))) {
        logger.info('📊 API 할당량 제한으로 폴백 추천 제공 (ID: $requestId)', tag: _tag);
        return _getFallbackRecommendations();
      }

      // 초기화 상태 확인
      if (!_isInitialized || _model == null) {
        logger.warning(
          '⚠️ AI 서비스가 초기화되지 않음. 자동 초기화 시도 (ID: $requestId)',
          tag: _tag,
        );
        await initialize();

        if (!_isInitialized) {
          logger.info('🔄 초기화 실패로 폴백 추천 제공 (ID: $requestId)', tag: _tag);
          return _getFallbackRecommendations();
        }
      }

      logger.debug('📊 추천 요청 데이터 (ID: $requestId):', tag: _tag);
      logger.debug('  - 현재 습관: ${currentHabits.length}개', tag: _tag);
      logger.debug(
        '  - 평균 완료율: ${(averageCompletionRate * 100).toStringAsFixed(1)}%',
        tag: _tag,
      );

      final prompt = _buildRecommendationsPrompt(
        currentHabits: currentHabits,
        weeklyProgress: weeklyProgress,
        averageCompletionRate: averageCompletionRate,
      );

      logger.debug('🔄 추천 요청 전송 중... (ID: $requestId)', tag: _tag);
      final response = await _safeModel.generateContent([Content.text(prompt)]);
      final aiResponse = response.text ?? '';

      final requestDuration = DateTime.now().difference(startTime);
      logger.info(
        '⚡ AI 추천 응답 수신 (소요시간: ${requestDuration.inMilliseconds}ms, ID: $requestId)',
        tag: _tag,
      );

      final parsedResult = _parseRecommendationsResponse(aiResponse);
      logger.info(
        '✅ AI 습관 추천 완료: ${parsedResult.length}개 추천 (ID: $requestId)',
        tag: _tag,
      );

      return parsedResult;
    } catch (e, stackTrace) {
      logger.error(
        '❌ AI 습관 추천 생성 실패 (ID: $requestId): $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      // 할당량 초과 에러 처리
      if (e.toString().contains('quota') || e.toString().contains('exceeded')) {
        logger.error('📊 API 할당량 초과로 폴백 추천 제공 (ID: $requestId)', tag: _tag);
        _initializationError = e.toString();
      }

      logger.info('🔄 폴백 추천 반환 (ID: $requestId)', tag: _tag);
      return _getFallbackRecommendations();
    }
  }

  /// 습관 패턴 예측 분석
  Future<Map<String, dynamic>> generatePatternPrediction({
    required List<Habit> habits,
    required Map<String, double> weeklyProgress,
    required Map<String, dynamic> monthlyTrends,
  }) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch;
    logger.info('🔮 AI 패턴 예측 생성 시작 (ID: $requestId)', tag: _tag);

    try {
      // 초기화 상태 확인
      if (!_isInitialized || _model == null) {
        logger.warning(
          '⚠️ AI 서비스가 초기화되지 않음. 자동 초기화 시도 (ID: $requestId)',
          tag: _tag,
        );
        await initialize();
      }

      final prompt = _buildPredictionPrompt(
        habits: habits,
        weeklyProgress: weeklyProgress,
        monthlyTrends: monthlyTrends,
      );

      logger.debug('🔄 예측 요청 전송 중... (ID: $requestId)', tag: _tag);
      final response = await _safeModel.generateContent([Content.text(prompt)]);
      final aiResponse = response.text ?? '';

      final requestDuration = DateTime.now().difference(startTime);
      logger.info(
        '⚡ AI 예측 응답 수신 (소요시간: ${requestDuration.inMilliseconds}ms, ID: $requestId)',
        tag: _tag,
      );

      final parsedResult = _parsePredictionResponse(aiResponse);
      logger.info('✅ AI 패턴 예측 완료 (ID: $requestId)', tag: _tag);

      return parsedResult;
    } catch (e, stackTrace) {
      logger.error(
        '❌ AI 패턴 예측 생성 실패 (ID: $requestId): $e',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      logger.info('🔄 폴백 예측 반환 (ID: $requestId)', tag: _tag);
      return _getFallbackPrediction();
    }
  }

  /// 인사이트 프롬프트 생성
  String _buildInsightsPrompt({
    required List<Habit> habits,
    required Map<String, double> weeklyProgress,
    required Map<String, dynamic> monthlyData,
    required int totalCompletedHabits,
    required int totalHabits,
    required int activeDays,
  }) {
    logger.debug('📝 인사이트 프롬프트 구성 중...', tag: _tag);

    final habitList = habits
        .map(
          (h) =>
              '- ${h.name}: ${h.streak}일 연속, ${h.isCompleted ? "오늘 완료" : "오늘 미완료"}',
        )
        .join('\n');

    final weeklyData = weeklyProgress.entries
        .map((e) => '${e.key}: ${(e.value * 100).toInt()}%')
        .join(', ');

    return '''
당신은 습관 형성 전문가이자 행동 분석가입니다. 사용자의 습관 데이터를 분석하여 개인화된 인사이트를 제공해주세요.

## 사용자 데이터:
현재 습관:
$habitList

주간 완료율: $weeklyData
월간 완료율: ${monthlyData['averageCompletionRate'] != null ? (monthlyData['averageCompletionRate'] * 100).toStringAsFixed(1) : '0.0'}%
활성 일수: $activeDays일
총 완료된 습관: $totalCompletedHabits/$totalHabits

## 분석 요청:
다음 JSON 형식으로 분석 결과를 제공해주세요:

{
  "mainInsight": "주요 인사이트 (한 문장)",
  "performance": {
    "level": "excellent|good|average|needs_improvement",
    "description": "성과 설명"
  },
  "patterns": [
    "패턴 1",
    "패턴 2"
  ],
  "recommendations": [
    "추천사항 1",
    "추천사항 2"
  ],
  "motivation": "동기부여 메시지"
}

한국어로 작성하고, 긍정적이고 건설적인 톤을 유지해주세요.
''';
  }

  /// 추천 프롬프트 생성
  String _buildRecommendationsPrompt({
    required List<Habit> currentHabits,
    required Map<String, double> weeklyProgress,
    required double averageCompletionRate,
  }) {
    final habitNames = currentHabits.map((h) => h.name).join(', ');

    return '''
현재 습관: $habitNames
평균 완료율: ${(averageCompletionRate * 100).toStringAsFixed(1)}%

사용자에게 적합한 새로운 습관 3개를 추천해주세요. JSON 배열 형식으로 응답해주세요:

[
  {
    "name": "습관 이름",
    "description": "설명",
    "difficulty": "easy|medium|hard",
    "category": "health|productivity|mindfulness|learning",
    "reason": "추천 이유"
  }
]
''';
  }

  /// 예측 프롬프트 생성
  String _buildPredictionPrompt({
    required List<Habit> habits,
    required Map<String, double> weeklyProgress,
    required Map<String, dynamic> monthlyTrends,
  }) {
    return '''
습관 데이터를 기반으로 다음 주 예측을 제공해주세요:

현재 습관: ${habits.map((h) => h.name).join(', ')}
주간 진행률: $weeklyProgress

JSON 형식으로 응답:
{
  "nextWeekPrediction": {
    "expectedCompletionRate": 0.75,
    "challengingDays": ["화요일", "목요일"],
    "recommendations": ["추천사항1", "추천사항2"]
  },
  "trends": {
    "improving": true,
    "description": "트렌드 설명"
  }
}
''';
  }

  // lib/data/services/ai_habit_analysis_service.dart
  // 추천 응답 파싱 메서드 수정

  /// 추천 응답 파싱
  List<Map<String, dynamic>> _parseRecommendationsResponse(String response) {
    logger.debug('🔍 추천 응답 파싱 시작', tag: _tag);
    logger.debug(
      '📄 원본 응답: ${response.substring(0, math.min(500, response.length))}...',
      tag: _tag,
    );

    try {
      // 1. 먼저 JSON 배열 형태로 파싱 시도 ([{...}, {...}])
      final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (arrayMatch != null) {
        final jsonString = arrayMatch.group(0)!;
        logger.debug('📦 JSON 배열 추출 성공', tag: _tag);

        final parsed = _parseJsonSafely(jsonString);
        if (parsed is List) {
          final recommendations = List<Map<String, dynamic>>.from(parsed);
          logger.info('✅ 추천 파싱 성공 (배열): ${recommendations.length}개', tag: _tag);

          // 제목 검증 및 수정
          final validatedRecommendations = _validateRecommendations(
            recommendations,
          );
          return validatedRecommendations;
        }
      }

      // 2. JSON 객체 형태로 파싱 시도 ({recommendations: [...]})
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (objectMatch != null) {
        final jsonString = objectMatch.group(0)!;
        logger.debug('📦 JSON 객체 추출 성공', tag: _tag);

        final parsed = _parseJsonSafely(jsonString);
        if (parsed is Map<String, dynamic> &&
            parsed['recommendations'] is List) {
          final recommendations = List<Map<String, dynamic>>.from(
            parsed['recommendations'],
          );
          logger.info('✅ 추천 파싱 성공 (객체): ${recommendations.length}개', tag: _tag);

          // 제목 검증 및 수정
          final validatedRecommendations = _validateRecommendations(
            recommendations,
          );
          return validatedRecommendations;
        }
      }

      // 3. 마크다운 코드 블록에서 JSON 추출 시도
      final codeBlockMatch = RegExp(
        r'```(?:json)?\s*(\[[\s\S]*?\]|\{[\s\S]*?\})\s*```',
      ).firstMatch(response);
      if (codeBlockMatch != null) {
        final jsonString = codeBlockMatch.group(1)!;
        logger.debug('📦 코드 블록에서 JSON 추출 성공', tag: _tag);

        final parsed = _parseJsonSafely(jsonString);
        if (parsed is List) {
          final recommendations = List<Map<String, dynamic>>.from(parsed);
          logger.info(
            '✅ 추천 파싱 성공 (코드블록): ${recommendations.length}개',
            tag: _tag,
          );

          final validatedRecommendations = _validateRecommendations(
            recommendations,
          );
          return validatedRecommendations;
        } else if (parsed is Map<String, dynamic> &&
            parsed['recommendations'] is List) {
          final recommendations = List<Map<String, dynamic>>.from(
            parsed['recommendations'],
          );
          logger.info(
            '✅ 추천 파싱 성공 (코드블록 객체): ${recommendations.length}개',
            tag: _tag,
          );

          final validatedRecommendations = _validateRecommendations(
            recommendations,
          );
          return validatedRecommendations;
        }
      }

      logger.warning('⚠️ JSON 파싱 실패 - 모든 방법 시도했으나 실패', tag: _tag);
    } catch (e) {
      logger.error('❌ 추천 응답 파싱 실패: $e', tag: _tag);
    }

    logger.warning('🔄 폴백 추천 반환', tag: _tag);
    return _getFallbackRecommendations();
  }

  /// 추천 데이터 검증 및 수정
  List<Map<String, dynamic>> _validateRecommendations(
    List<Map<String, dynamic>> recommendations,
  ) {
    logger.debug('🔍 추천 데이터 검증 시작: ${recommendations.length}개', tag: _tag);

    final validatedList = <Map<String, dynamic>>[];

    for (int i = 0; i < recommendations.length; i++) {
      final recommendation = Map<String, dynamic>.from(recommendations[i]);

      // 필수 필드 검증 및 기본값 설정
      _validateAndFixField(recommendation, 'title', 'name', '새로운 습관 ${i + 1}');
      _validateAndFixField(
        recommendation,
        'description',
        'desc',
        '건강한 새로운 습관입니다.',
      );
      _validateAndFixField(recommendation, 'category', 'cat', '일반');
      _validateAndFixField(recommendation, 'difficulty', 'diff', '보통');
      _validateAndFixField(recommendation, 'timeRequired', 'time', '5분');

      // benefits 배열 검증
      if (recommendation['benefits'] == null ||
          recommendation['benefits'] is! List) {
        recommendation['benefits'] = ['건강 개선', '습관 형성'];
      }

      // startingTip 검증
      if (recommendation['startingTip'] == null ||
          recommendation['startingTip'].toString().isEmpty) {
        recommendation['startingTip'] = '작은 것부터 시작해보세요.';
      }

      logger.debug('📝 추천 ${i + 1}: ${recommendation['title']}', tag: _tag);
      validatedList.add(recommendation);
    }

    logger.info('✅ 추천 데이터 검증 완료: ${validatedList.length}개', tag: _tag);
    return validatedList;
  }

  /// 필드 검증 및 수정 헬퍼 메서드
  void _validateAndFixField(
    Map<String, dynamic> data,
    String primaryKey,
    String? alternativeKey,
    String defaultValue,
  ) {
    // 1차: 기본 키 확인
    if (data[primaryKey] != null && data[primaryKey].toString().isNotEmpty) {
      return; // 이미 유효한 값이 있음
    }

    // 2차: 대체 키 확인
    if (alternativeKey != null &&
        data[alternativeKey] != null &&
        data[alternativeKey].toString().isNotEmpty) {
      data[primaryKey] = data[alternativeKey];
      logger.debug('🔄 필드 매핑: $alternativeKey -> $primaryKey', tag: _tag);
      return;
    }

    // 3차: 기본값 설정
    data[primaryKey] = defaultValue;
    logger.debug('⚠️ 기본값 설정: $primaryKey = $defaultValue', tag: _tag);
  }

  /// 안전한 JSON 파싱 (수정 버전)
  dynamic _parseJsonSafely(String jsonString) {
    try {
      logger.debug('🔄 JSON 파싱 시도', tag: _tag);

      // JSON 문자열 정리
      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();

      logger.debug('🧹 JSON 정리 완료', tag: _tag);

      // dart:convert 사용하여 실제 JSON 파싱
      final result = jsonDecode(cleanJson);
      logger.debug('✅ JSON 파싱 성공', tag: _tag);

      return result;
    } catch (e) {
      logger.error('❌ JSON 파싱 실패: $e', tag: _tag);
      logger.debug(
        '🔍 파싱 실패한 JSON: ${jsonString.substring(0, math.min(200, jsonString.length))}...',
        tag: _tag,
      );
      return null;
    }
  }

  /// 폴백 추천 (수정 버전)
  List<Map<String, dynamic>> _getFallbackRecommendations() {
    logger.debug('🔄 폴백 추천 생성', tag: _tag);

    return [
      {
        'title': '아침 스트레칭',
        'description': '하루를 상쾌하게 시작하는 5분 스트레칭',
        'category': '건강',
        'difficulty': '쉬움',
        'timeRequired': '5분',
        'benefits': ['혈액순환 개선', '하루 에너지 충전'],
        'startingTip': '기상 직후 침대에서 간단한 동작부터 시작하세요.',
      },
      {
        'title': '감사 일기',
        'description': '하루 3가지 감사한 일 적기',
        'category': '마음챙김',
        'difficulty': '쉬움',
        'timeRequired': '3분',
        'benefits': ['긍정적 사고', '스트레스 완화'],
        'startingTip': '잠들기 전 오늘 일어난 좋은 일들을 떠올려보세요.',
      },
      {
        'title': '물 마시기',
        'description': '하루 8잔의 물을 마시는 건강 습관',
        'category': '건강',
        'difficulty': '쉬움',
        'timeRequired': '1분',
        'benefits': ['수분 보충', '신진대사 촉진'],
        'startingTip': '스마트폰에 물 마시기 알림을 설정해보세요.',
      },
    ];
  }

  /// 예측 응답 파싱
  Map<String, dynamic> _parsePredictionResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return json.decode(jsonStr);
      }
    } catch (e) {
      logger.warning('📄 AI 예측 응답 파싱 실패, 폴백 예측 사용: $e', tag: _tag);
    }

    return _getFallbackPrediction();
  }

  // lib/data/services/ai_habit_analysis_service.dart
  // _parseInsightsResponse 메서드 완전 구현

  /// 인사이트 응답 파싱
  Map<String, dynamic> _parseInsightsResponse(String response) {
    logger.debug('🔍 인사이트 응답 파싱 시작', tag: _tag);
    logger.debug(
      '📄 원본 응답: ${response.substring(0, math.min(500, response.length))}...',
      tag: _tag,
    );

    try {
      // 1. 먼저 JSON 객체 형태로 파싱 시도 ({...})
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (objectMatch != null) {
        final jsonString = objectMatch.group(0)!;
        logger.debug('📦 JSON 객체 추출 성공', tag: _tag);

        final parsed = _parseJsonSafely(jsonString);
        if (parsed is Map<String, dynamic>) {
          logger.info('✅ 인사이트 파싱 성공 (객체)', tag: _tag);

          // 인사이트 데이터 검증 및 수정
          final validatedInsights = _validateInsights(parsed);
          return validatedInsights;
        }
      }

      // 2. 마크다운 코드 블록에서 JSON 추출 시도
      final codeBlockMatch = RegExp(
        r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      ).firstMatch(response);
      if (codeBlockMatch != null) {
        final jsonString = codeBlockMatch.group(1)!;
        logger.debug('📦 코드 블록에서 JSON 추출 성공', tag: _tag);

        final parsed = _parseJsonSafely(jsonString);
        if (parsed is Map<String, dynamic>) {
          logger.info('✅ 인사이트 파싱 성공 (코드블록)', tag: _tag);

          final validatedInsights = _validateInsights(parsed);
          return validatedInsights;
        }
      }

      // 3. 텍스트에서 직접 필드 추출 시도 (JSON이 아닌 경우)
      logger.debug('📝 텍스트에서 직접 필드 추출 시도', tag: _tag);
      final extractedInsights = _extractInsightsFromText(response);
      if (extractedInsights.isNotEmpty) {
        logger.info('✅ 인사이트 텍스트 추출 성공', tag: _tag);
        return extractedInsights;
      }

      logger.warning('⚠️ 인사이트 파싱 실패 - 모든 방법 시도했으나 실패', tag: _tag);
    } catch (e) {
      logger.error('❌ 인사이트 응답 파싱 실패: $e', tag: _tag);
    }

    logger.warning('🔄 폴백 인사이트 반환', tag: _tag);
    return _getFallbackInsights();
  }

  /// 인사이트 데이터 검증 및 수정
  Map<String, dynamic> _validateInsights(Map<String, dynamic> insights) {
    logger.debug('🔍 인사이트 데이터 검증 시작', tag: _tag);

    final validated = Map<String, dynamic>.from(insights);

    // 필수 필드 검증 및 기본값 설정
    _validateAndFixInsightField(
      validated,
      'mainInsight',
      'insight',
      '습관 형성을 위한 노력이 계속되고 있습니다.',
    );
    _validateAndFixInsightField(
      validated,
      'motivation',
      'motivationMessage',
      '오늘도 한 걸음씩 나아가고 있습니다!',
    );
    _validateAndFixInsightField(validated, 'nextGoal', 'goal', '꾸준히 실행하기');
    _validateAndFixInsightField(
      validated,
      'personalizedTip',
      'tip',
      '매일 같은 시간에 실행해보세요.',
    );

    // 배열 필드 검증 - patterns
    if (!_validateArrayField(validated, 'patterns')) {
      // strengths에서 patterns로 매핑 시도
      if (_validateArrayField(validated, 'strengths')) {
        validated['patterns'] = validated['strengths'];
        logger.debug('🔄 필드 매핑: strengths -> patterns', tag: _tag);
      } else {
        validated['patterns'] = [
          '매일 조금씩이라도 실행하는 것이 중요합니다.',
          '규칙적인 시간에 습관을 실행해보세요.',
        ];
      }
    }

    // 배열 필드 검증 - recommendations
    if (!_validateArrayField(validated, 'recommendations')) {
      // improvements에서 recommendations로 매핑 시도
      if (_validateArrayField(validated, 'improvements')) {
        validated['recommendations'] = validated['improvements'];
        logger.debug('🔄 필드 매핑: improvements -> recommendations', tag: _tag);
      } else {
        validated['recommendations'] = [
          '작은 목표부터 시작하세요.',
          '습관을 놓쳤을 때 자책하지 마세요.',
        ];
      }
    }

    // performance 객체 검증
    if (!_validatePerformanceField(validated)) {
      validated['performance'] = {
        'level': 'good',
        'description': '현재 진행 상황을 분석 중입니다.',
      };
    }

    logger.info('✅ 인사이트 데이터 검증 완료', tag: _tag);
    logger.debug('🎯 검증된 키: ${validated.keys.toList()}', tag: _tag);

    return validated;
  }

  /// 인사이트 필드 검증 및 수정 헬퍼 메서드
  void _validateAndFixInsightField(
    Map<String, dynamic> data,
    String primaryKey,
    String? alternativeKey,
    String defaultValue,
  ) {
    // 1차: 기본 키 확인
    if (data[primaryKey] != null && data[primaryKey].toString().isNotEmpty) {
      return; // 이미 유효한 값이 있음
    }

    // 2차: 대체 키 확인
    if (alternativeKey != null &&
        data[alternativeKey] != null &&
        data[alternativeKey].toString().isNotEmpty) {
      data[primaryKey] = data[alternativeKey];
      logger.debug('🔄 필드 매핑: $alternativeKey -> $primaryKey', tag: _tag);
      return;
    }

    // 3차: 기본값 설정
    data[primaryKey] = defaultValue;
    logger.debug('⚠️ 기본값 설정: $primaryKey = $defaultValue', tag: _tag);
  }

  /// 배열 필드 검증
  bool _validateArrayField(Map<String, dynamic> data, String key) {
    return data[key] != null &&
        data[key] is List &&
        (data[key] as List).isNotEmpty;
  }

  /// performance 필드 검증
  bool _validatePerformanceField(Map<String, dynamic> data) {
    if (data['performance'] == null || data['performance'] is! Map) {
      return false;
    }

    final performance = data['performance'] as Map<String, dynamic>;
    return performance['level'] != null || performance['description'] != null;
  }

  /// 텍스트에서 인사이트 추출 (JSON이 아닌 경우)
  Map<String, dynamic> _extractInsightsFromText(String text) {
    logger.debug('📝 텍스트에서 인사이트 추출 시작', tag: _tag);

    final extracted = <String, dynamic>{};

    try {
      // 간단한 패턴 매칭으로 주요 내용 추출
      final lines =
          text.split('\n').where((line) => line.trim().isNotEmpty).toList();

      String? mainInsight;
      final patterns = <String>[];
      final recommendations = <String>[];
      String? motivation;

      for (final line in lines) {
        final trimmed = line.trim();

        // 메인 인사이트 추출 (첫 번째 의미있는 문장)
        if (mainInsight == null &&
            trimmed.length > 20 &&
            (trimmed.contains('습관') ||
                trimmed.contains('분석') ||
                trimmed.contains('패턴'))) {
          mainInsight = trimmed.replaceAll(RegExp(r'^[-•*]\s*'), '');
        }

        // 패턴이나 강점 추출
        if (trimmed.contains('패턴') ||
            trimmed.contains('강점') ||
            trimmed.contains('잘하고')) {
          patterns.add(trimmed.replaceAll(RegExp(r'^[-•*]\s*'), ''));
        }

        // 추천사항이나 개선점 추출
        if (trimmed.contains('추천') ||
            trimmed.contains('개선') ||
            trimmed.contains('제안')) {
          recommendations.add(trimmed.replaceAll(RegExp(r'^[-•*]\s*'), ''));
        }

        // 동기부여 메시지 추출
        if (trimmed.contains('계속') ||
            trimmed.contains('힘내') ||
            trimmed.contains('응원')) {
          motivation = trimmed.replaceAll(RegExp(r'^[-•*]\s*'), '');
        }
      }

      // 추출된 내용으로 구조체 생성
      if (mainInsight != null) {
        extracted['mainInsight'] = mainInsight;
      }

      if (patterns.isNotEmpty) {
        extracted['patterns'] = patterns.take(3).toList();
      }

      if (recommendations.isNotEmpty) {
        extracted['recommendations'] = recommendations.take(3).toList();
      }

      if (motivation != null) {
        extracted['motivation'] = motivation;
      }

      // 기본값들 추가
      extracted['nextGoal'] = '이번 주 목표 달성하기';
      extracted['personalizedTip'] = '습관을 특정 시간과 연결하여 루틴화해보세요.';
      extracted['performance'] = {
        'level': 'good',
        'description': '꾸준한 노력이 보입니다.',
      };

      logger.debug('📊 텍스트 추출 결과: ${extracted.keys.toList()}', tag: _tag);
    } catch (e) {
      logger.error('❌ 텍스트 추출 실패: $e', tag: _tag);
    }

    return extracted;
  }

  /// 폴백 인사이트 (향상된 버전)
  Map<String, dynamic> _getFallbackInsights() {
    logger.debug('🔄 향상된 폴백 인사이트 생성', tag: _tag);

    return {
      'mainInsight': '습관 형성은 꾸준함이 가장 중요합니다. 지금까지의 노력이 의미 있는 변화를 만들어가고 있습니다.',
      'performance': {
        'level': 'good',
        'description': '현재 진행 상황을 분석하여 더 나은 방향을 제시하겠습니다.',
      },
      'patterns': [
        '매일 조금씩이라도 실행하는 것이 중요합니다.',
        '규칙적인 시간에 습관을 실행해보세요.',
        '완벽하지 않아도 괜찮습니다. 지속성이 핵심이에요.',
      ],
      'recommendations': [
        '작은 목표부터 시작하세요.',
        '습관을 놓쳤을 때 자책하지 마세요.',
        '환경을 습관에 유리하게 만들어보세요.',
        '습관과 보상을 연결해보세요.',
      ],
      'motivation': '오늘도 한 걸음씩 나아가고 있습니다! 포기하지 마세요 💪',
      'nextGoal': '내일은 하나라도 더 완료해보세요',
      'personalizedTip':
          '습관을 특정 시간과 연결하여 루틴화해보세요. 예를 들어 양치질 후에 물 마시기를 연결하는 것처럼요.',
    };
  }

  /// 폴백 예측
  Map<String, dynamic> _getFallbackPrediction() {
    logger.info('🔄 폴백 예측 제공', tag: _tag);
    return {
      'nextWeekPrediction': {
        'expectedCompletionRate': 0.70,
        'challengingDays': ['월요일', '금요일'],
        'recommendations': ['주말에 다음 주 계획을 세워보세요.', '어려운 날에는 목표를 낮춰도 괜찮습니다.'],
      },
      'trends': {'improving': true, 'description': '꾸준한 노력으로 개선되고 있습니다.'},
    };
  }
}
