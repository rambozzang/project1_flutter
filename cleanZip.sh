#!/bin/bash

# 스크립트 실행 중 오류 발생 시 즉시 중단
set -e

# Flutter 앱 빌드
echo "Building Flutter app..."
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info.zip

# 지정된 디렉토리로 이동
cd ~/work/app/flutter/project1/build/app/intermediates/merged_native_libs/release/out/lib

# 현재 디렉토리 출력 (디버깅용)
echo "Current directory: $(pwd)"

# __MACOSX 디렉토리 제거
find . -name "__MACOSX" -type d -exec rm -rf {} +

# .DS_Store 파일 제거
find . -name ".DS_Store" -type f -delete

# 제거된 항목 확인 메시지 출력
echo "Removed __MACOSX directories and .DS_Store files"

# ZIP 파일 생성
zip -r ../symbols_clean.zip ./*

# 작업 완료 메시지 출력
echo "ZIP file created: ~/work/app/flutter/project1/build/symbols_clean.zip"

echo "Build and clean-up process completed successfully."