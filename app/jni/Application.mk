APP_ABI := arm64-v8a armeabi-v7a
# dsam3 (minSdk 29) 통합 타깃 — 내부 filesDir 실행이라 스토리지 권한도 불필요해진다
APP_PLATFORM := android-29
APP_OPTIM := release
APP_STL := c++_shared
APP_CPPFLAGS := -std=c++14 -frtti -fexceptions
# NDK r27+: 16KB 페이지 기기(Android 15+, targetSdk 35+) 로드 호환 — ndk-build 모듈 전체에
# -Wl,-z,max-page-size=16384 를 적용한다. Makefile 로 빌드되는 openal/ruby 는 별도 플래그 필요.
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true
