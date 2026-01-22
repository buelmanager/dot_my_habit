# 점(Dot) - AI 습관 분석 앱

> AI 기반 습관 추적 및 분석 Flutter 앱

<p align="center">
  <img src="assets/images/app_icon.png" alt="Dot Habit Logo" width="120"/>
</p>

## 프로젝트 소개

**점(Dot)**은 사용자의 습관을 추적하고 **Google Gemini AI**를 활용하여 패턴을 분석하는 크로스 플랫폼 습관 관리 앱입니다. 매일의 작은 점(습관 완료)들이 모여 큰 변화를 만든다는 의미를 담고 있습니다.

---

## 기술 스택

### 핵심 프레임워크

| 기술 | 버전 | 설명 |
|------|------|------|
| **Flutter** | 3.7+ | 크로스 플랫폼 UI 프레임워크 |
| **Dart** | ^3.7.2 | 프로그래밍 언어 |

### 상태 관리

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **flutter_riverpod** | ^2.6.1 | 반응형 상태 관리 |
| **riverpod_annotation** | ^2.6.1 | 코드 생성 기반 Riverpod |
| **provider** | ^6.1.4 | 레거시 상태 관리 |

### 라우팅 & 네비게이션

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **go_router** | ^15.0.0 | 선언형 라우팅 |

### AI & 머신러닝

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **google_generative_ai** | ^0.2.0 | Google Gemini AI 연동 |

### 로컬 데이터 저장

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **sqflite** | ^2.4.2 | SQLite 로컬 데이터베이스 |
| **shared_preferences** | ^2.5.3 | 간단한 키-값 저장소 |
| **path_provider** | ^2.1.5 | 파일 시스템 경로 제공 |

### 차트 & 시각화

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **fl_chart** | ^0.71.0 | 인터랙티브 차트 라이브러리 |

### 알림

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **flutter_local_notifications** | ^19.1.0 | 로컬 푸시 알림 |
| **timezone** | ^0.10.0 | 타임존 처리 |

### 인앱 결제 & 구독

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **purchases_flutter** | ^8.10.1 | RevenueCat 인앱 결제 |

### 유틸리티

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **uuid** | ^4.2.2 | 고유 ID 생성 |
| **intl** | ^0.20.2 | 국제화 및 날짜 포맷팅 |
| **equatable** | ^2.0.5 | 값 비교 헬퍼 |
| **collection** | ^1.17.2 | 컬렉션 유틸리티 |
| **logger** | ^2.5.0 | 로깅 시스템 |

### 코드 생성 (Dev Dependencies)

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **freezed** | ^2.4.7 | 불변 클래스 생성 |
| **freezed_annotation** | ^2.4.1 | Freezed 어노테이션 |
| **json_annotation** | ^4.8.1 | JSON 직렬화 어노테이션 |
| **build_runner** | ^2.4.8 | 코드 생성 실행기 |

### 기타

| 패키지 | 버전 | 용도 |
|--------|------|------|
| **flutter_dotenv** | ^5.0.2 | 환경 변수 관리 |
| **permission_handler** | ^12.0.0+1 | 권한 관리 |
| **file_picker** | ^10.1.2 | 파일 선택 |
| **share_plus** | ^10.1.4 | 공유 기능 |
| **package_info_plus** | ^8.3.0 | 앱 정보 조회 |
| **flutter_launcher_icons** | ^0.13.1 | 앱 아이콘 생성 |

---

## 아키텍처

### Clean Architecture 기반 레이어 구조

```
lib/
├── main.dart                 # 앱 진입점
├── app_router.dart           # GoRouter 설정
├── app_providers.dart        # 전역 Provider 정의
│
├── config/                   # 설정
│   ├── theme.dart           # 앱 테마 설정
│   └── routes.dart          # 라우트 상수
│
├── constants/                # 상수
│   └── app_colors.dart      # 색상 상수
│
├── core/                     # 핵심 유틸리티
│   └── logger.dart          # 로깅 시스템
│
├── data/                     # 데이터 레이어
│   ├── datasources/         # 데이터 소스
│   │   └── local/
│   │       └── database.dart    # SQLite 데이터베이스
│   ├── dtos/                # Data Transfer Objects
│   ├── models/              # 데이터 모델
│   │   └── habit.dart       # 습관 모델
│   ├── repositories/        # 레포지토리 구현
│   └── services/            # 비즈니스 서비스
│       ├── ai_habit_analysis_service.dart  # AI 분석 서비스
│       ├── backup_service.dart             # 백업 서비스
│       ├── premium_service.dart            # 프리미엄 기능
│       ├── revenuecat_service.dart         # 결제 서비스
│       └── subscription_service.dart       # 구독 관리
│
├── domain/                   # 도메인 레이어
│   └── models/              # 도메인 모델
│
├── generated/                # 자동 생성 코드
│   └── assets.dart          # 에셋 상수
│
└── presentation/             # 프레젠테이션 레이어
    ├── common_widgets/      # 공통 위젯
    ├── viewmodels/          # 뷰모델
    │   └── home_viewmodel.dart
    ├── widgets/             # 재사용 위젯
    │   ├── app_scaffold.dart
    │   ├── dot_bottom_navigation_bar.dart
    │   └── premium_required_dialog.dart
    ├── screens/             # 화면
    │   ├── home/            # 홈 화면
    │   ├── pattern/         # 패턴 분석 화면
    │   │   ├── pattern_screen.dart
    │   │   ├── views/       # 뷰 컴포넌트
    │   │   └── widgets/     # 패턴 위젯들
    │   └── subscription/    # 구독 화면
    ├── settings/            # 설정 화면
    └── statistics/          # 통계 화면
```

---

## 주요 기능

### 1. 습관 관리
- 습관 생성, 수정, 삭제
- 일일 습관 완료 체크
- 연속 달성 (Streak) 추적
- 알림 시간 설정

### 2. AI 패턴 분석 (Google Gemini)
- 습관 패턴 예측
- 개인화된 습관 추천
- AI 인사이트 요약
- 습관 상관관계 분석

### 3. 통계 & 시각화
- 주간/월간 히트맵
- 시간대별 완료 차트
- 월간 트렌드 분석
- 목표 달성률 카드
- 최장 연속 기록

### 4. 프리미엄 기능
- RevenueCat 연동 인앱 결제
- 구독 관리
- 프리미엄 전용 AI 분석

### 5. 데이터 관리
- SQLite 로컬 저장
- 백업 및 복원
- 데이터 내보내기

---

## 데이터베이스 스키마

### habits 테이블
```sql
CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  isCompleted INTEGER NOT NULL DEFAULT 0,
  isEmphasized INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  completedAt TEXT,
  reminderTime TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### habit_logs 테이블
```sql
CREATE TABLE habit_logs (
  id TEXT PRIMARY KEY,
  habitId TEXT NOT NULL,
  date TEXT NOT NULL,
  isCompleted INTEGER NOT NULL DEFAULT 0,
  completedAt TEXT,
  FOREIGN KEY (habitId) REFERENCES habits(id)
)
```

### settings 테이블
```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
```

---

## 설치 및 실행

### 사전 요구사항
- Flutter SDK 3.7 이상
- Dart SDK 3.7.2 이상
- Android Studio / VS Code
- Xcode (iOS 빌드 시)

### 환경 변수 설정

`assets/.env` 파일을 생성하고 다음 내용을 추가:

```env
GEMINI_API_KEY=your_gemini_api_key_here
REVENUECAT_API_KEY=your_revenuecat_api_key_here
```

### 설치 및 실행

```bash
# 저장소 클론
git clone https://github.com/buelmanager/dot_my_habit.git

# 디렉토리 이동
cd dot_my_habit

# 의존성 설치
flutter pub get

# 코드 생성 (Freezed, JSON 직렬화)
flutter pub run build_runner build --delete-conflicting-outputs

# 앱 아이콘 생성
flutter pub run flutter_launcher_icons

# 실행
flutter run
```

### 플랫폼별 빌드

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 지원 플랫폼

| 플랫폼 | 지원 |
|--------|------|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |

---

## 디자인 패턴

- **Clean Architecture** - 레이어 분리
- **MVVM** - ViewModel을 통한 UI 로직 분리
- **Repository Pattern** - 데이터 소스 추상화
- **Singleton** - 서비스 인스턴스 관리
- **Factory** - 모델 객체 생성
- **Immutable State** - Freezed를 활용한 불변 상태

---

## 라이선스

© 2025 buelmanager. All Rights Reserved.

---

## 연락처

- **GitHub**: [@buelmanager](https://github.com/buelmanager)
- **Email**: buelmanager@gmail.com
