import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 앱의 메인 테마
final appTheme = ThemeData(
  // Material 3 디자인 사용
  useMaterial3: true,

  // 기본 색상 테마
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),

  // 앱 바 테마
  appBarTheme: const AppBarTheme(
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),

  // 스캐폴드 배경색
  scaffoldBackgroundColor: Colors.white,

  // 다이얼로그 테마 (AlertDialog 배경색상 설정)
  dialogTheme: const DialogTheme(
    backgroundColor: Colors.white, // 다이얼로그 배경색
    elevation: 8, // 그림자 높이
    shape: RoundedRectangleBorder(
      // 모서리 둥글게
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    titleTextStyle: TextStyle(
      // 제목 스타일
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      // 내용 스타일
      color: Colors.black87,
      fontSize: 16,
      height: 1.4,
    ),
    actionsPadding: EdgeInsets.symmetric(
      // 버튼 패딩
      horizontal: 16,
      vertical: 8,
    ),
  ),

  // 텍스트 테마
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    ),
  ),

  // 버튼 테마
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),

  // 텍스트 버튼 테마
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),

  // 카드 테마
  cardTheme: CardTheme(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
    ),
  ),

  // 디바이더 테마
  dividerTheme: const DividerThemeData(
    color: Colors.black12,
    thickness: 1,
    space: 1,
  ),

  // 입력 장식 테마
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black.withOpacity(0.03),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black, width: 1),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    hintStyle: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14),
  ),

  // 슬라이더 테마
  sliderTheme: SliderThemeData(
    activeTrackColor: Colors.black,
    inactiveTrackColor: Colors.black.withOpacity(0.1),
    thumbColor: Colors.black,
    overlayColor: Colors.black.withOpacity(0.1),
    valueIndicatorColor: Colors.black,
    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
  ),

  // 스위치 테마
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      }
      return Colors.white;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.black;
      }
      return Colors.black.withOpacity(0.1);
    }),
  ),

  // 체크박스 테마
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.black;
      }
      return null;
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),

  // 아이콘 테마
  iconTheme: IconThemeData(color: Colors.black.withOpacity(0.7), size: 24),

  // Fab 테마
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 2,
    shape: CircleBorder(),
  ),

  // 진행 표시기 테마
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Colors.black,
    circularTrackColor: Colors.black12,
    linearTrackColor: Colors.black12,
  ),

  // BottomSheet 테마 (추가 옵션)
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),

  // SnackBar 테마 (추가 옵션)
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.black,
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),
);
