#!/bin/bash

# This script downloads/git clones project dependencies
# such as libogg, SDL2, Ruby, etc.

GIT_ARGS="-q -c advice.detachedHead=false --single-branch --depth 1"

# Xiph libogg
if [[ ! -d "libogg" ]]; then
  echo "Downloading libogg..."
  git clone $GIT_ARGS -b v1.3.5 https://github.com/xiph/ogg libogg
fi

# Xiph libvorbis
if [[ ! -d "libvorbis" ]]; then
  echo "Downloading libvorbis..."
  git clone $GIT_ARGS -b v1.3.7 https://github.com/xiph/vorbis libvorbis
fi

# Xiph libtheora
if [[ ! -d "libtheora" ]]; then
  echo "Downloading libtheora..."
  wget -q https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-1.1.1.tar.gz
  tar -xzf libtheora-1.1.1.tar.gz
  mv libtheora-1.1.1 libtheora
  rm -f libtheora-1.1.1.tar.gz
fi

# GNU libiconv
if [[ ! -d "libiconv" ]]; then
  echo "Downloading libiconv..."
  wget -q https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz
  tar -xzf libiconv-1.17.tar.gz
  mv libiconv-1.17 libiconv
  rm -f libiconv-1.17.tar.gz
fi

# Freedesktop uchardet
if [[ ! -d "uchardet" ]]; then
  echo "Downloading uchardet..."
  git clone $GIT_ARGS -b v0.0.8 https://gitlab.freedesktop.org/uchardet/uchardet.git/ uchardet
fi

# Freedesktop Pixman
if [[ ! -d "pixman" ]]; then
  echo "Downloading Pixman..."
  git clone $GIT_ARGS -b pixman-0.42.2 https://gitlab.freedesktop.org/pixman/pixman.git/ pixman
fi

# PhysicsFS
if [[ ! -d "physfs" ]]; then
  echo "Downloading PhysicsFS..."
  git clone $GIT_ARGS -b release-3.2.0 https://github.com/icculus/physfs physfs
fi

# OpenAL Soft 1.23.0
if [[ ! -d "openal" ]]; then
  echo "Downloading OpenAL Soft..."
  git clone $GIT_ARGS -b 1.23.0 https://github.com/kcat/openal-soft openal
fi

# SDL2
if [[ ! -d "SDL2" ]]; then
  echo "Downloading SDL2..."
  git clone $GIT_ARGS -b release-2.26.3 https://github.com/libsdl-org/SDL SDL2
fi

# Patch SDL2 Java binding package: org.libsdl.app -> com.skyksit.dsam3.rgss.sdl
# The Java-side classes live in app/src/main/java/com/skyksit/dsam3/rgss/sdl/ so that
# they can coexist with dsam3's SDL3 org.libsdl.app layer in one APK (dex-level FQCN clash).
# SDL_android.c defines SDL_JAVA_PREFIX unconditionally (no #ifndef guard), and
# src/hidapi/android/hid.cpp has its own copy, so -D flags cannot override it — patch sources.
# Idempotent: grep finds nothing on an already-patched tree.
if [[ -d "SDL2" ]]; then
  SDL2_PATCH_FILES=$(grep -rl 'org_libsdl_app\|org/libsdl/app' SDL2/src SDL2/include 2>/dev/null || true)
  if [[ -n "$SDL2_PATCH_FILES" ]]; then
    echo "Patching SDL2 Java package prefix (org.libsdl.app -> com.skyksit.dsam3.rgss.sdl)..."
    echo "$SDL2_PATCH_FILES" | xargs sed -i \
      -e 's|org_libsdl_app|com_skyksit_dsam3_rgss_sdl|g' \
      -e 's|org/libsdl/app|com/skyksit/dsam3/rgss/sdl|g'
  fi

  # NDK r27 은 ALooper_pollAll 을 컴파일 에러로 막는다 (r26 에서 deprecated).
  # SDL 2.30 의 upstream 수정과 동일하게 ALooper_pollOnce 로 교체 (시그니처 동일).
  SDL2_LOOPER_FILES=$(grep -rl 'ALooper_pollAll' SDL2/src 2>/dev/null || true)
  if [[ -n "$SDL2_LOOPER_FILES" ]]; then
    echo "Patching SDL2 ALooper_pollAll -> ALooper_pollOnce (NDK r27)..."
    echo "$SDL2_LOOPER_FILES" | xargs sed -i 's|ALooper_pollAll|ALooper_pollOnce|g'
  fi
fi

# SDL2_image
if [[ ! -d "SDL2_image" ]]; then
  echo "Downloading SDL2_image..."
  git clone $GIT_ARGS --recurse-submodules -b release-2.6.3 https://github.com/libsdl-org/SDL_image SDL2_image
fi

# SDL2_ttf
if [[ ! -d "SDL2_ttf" ]]; then
  echo "Downloading SDL2_ttf..."
  git clone $GIT_ARGS --recurse-submodules -b release-2.20.2 https://github.com/libsdl-org/SDL_ttf SDL2_ttf
fi

# harfbuzz: hb.hh 가 "#pragma GCC diagnostic error -Wcast-function-type" 으로 경고를
# 에러로 승격시키는데, clang 16+(NDK r26/r27)에선 -strict 하위 그룹까지 포함되어
# hb-ft.cc 의 FT_Generic_Finalizer 캐스트가 빌드를 죽인다 (upstream 은 8.x 에서
# 콜백 시그니처를 고쳐 해결). include 시점에 재승격되므로 hb-ft.cc 쪽 pragma 로는
# 못 막고, hb.hh 의 해당 pragma 자체를 ignored 로 바꾼다. 멱등.
HB_HH="SDL2_ttf/external/harfbuzz/src/hb.hh"
if [[ -f "$HB_HH" ]] && grep -q 'diagnostic error *"-Wcast-function-type"' "$HB_HH"; then
  echo "Patching harfbuzz hb.hh (-Wcast-function-type error -> ignored)..."
  sed -i 's|diagnostic error\( *\)"-Wcast-function-type"|diagnostic ignored\1"-Wcast-function-type"|' "$HB_HH"
fi

# SDL2_sound
if [[ ! -d "SDL2_sound" ]]; then
  echo "Downloading SDL2_sound..."
  git clone $GIT_ARGS -b v2.0.1 https://github.com/icculus/SDL_sound SDL2_sound
fi

# OpenSSL 1.1.1t
if [[ ! -d "openssl" ]]; then
  echo "Downloading OpenSSL..."
  git clone $GIT_ARGS -b OpenSSL_1_1_1t https://github.com/openssl/openssl openssl
fi

# Ruby 3.1.0 (patched for mkxp-z)
if [[ ! -d "ruby" ]]; then
  echo "Downloading Ruby..."
  git clone $GIT_ARGS -b mkxp-z-3.1 https://github.com/mkxp-z/ruby ruby
fi

echo "Done!"
