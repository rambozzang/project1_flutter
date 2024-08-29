# SkySnap App by CodeLabtiger

#ISO 업로드 하기


1.  flutter build ipa
2. build/ios/archive/Runner.xcarchive 를 XCode로 열기
3. Validate 실행
4. Distribution 실행
5. 앱컨넥터스토어 업로드된 빌드 번호 확인 가능

#안드로이드 

1. flutter build appbundle --release --obfuscate --split-debug-info=./debug-info.zip 실행
  flutter build apk --release --target-platform=android-arm64 --split-debug-info=./debug-info
2. App bundle 탐색기에 업로드
 - build/app/outputs/bundle/release/app-release.aab

 

# 안드로이드 디버그 기호 파일 업로드
**app/build/app/intermediates/merged_nativ_libs/프로젝트폴더/out/lib**
- x86_64
- x86
- armeabi-v7a
- arm64-v8a

4개 폴더 모두 압축

압축 폴더 안에 **__MACOSX**, **.DS_Store**를 포함하면 안됨.

### **폴더 안에서 아래 명령어로 삭제 해준다.** (MAC에서 마우스 우측 클릭으로 압축하면 안됨 터미널 이용!)

https://hooun.tistory.com/432

work/app/flutter/project1/build/app/intermediates/merged_native_libs/release/out/lib

- find . -name "__MACOSX" -exec rm -rf {} +
- find . -name ".DS_Store" -exec rm -rf {} +
- zip -r ../symbols_clean.zip ./*

symbols_clean.zip  파일 업로드 끝!!

#1차 심사
네, 앱스토어 심사 결과를 분석해 드리겠습니다. 앱이 거절된 주요 이유와 해결 방안을 정리해 드리겠습니다:

1. 사용자 생성 콘텐츠 관련 안전 지침 (Guideline 1.2) 위반:
   - 문제: 사용자 생성 콘텐츠에 대한 필요한 안전 조치가 부족함.
   - 해결 방안:
     - 사용자 이용 약관(EULA) 구현 및 부적절한 콘텐츠 금지 명시
     - 부적절한 콘텐츠 필터링 방법 구현
     - 사용자가 부적절한 콘텐츠를 신고할 수 있는 기능 추가
     - 사용자가 악성 사용자를 차단할 수 있는 기능 추가
     - 24시간 이내에 신고된 콘텐츠에 대응하는 시스템 구축

2. 앱 완성도 문제 (Guideline 2.1):
   - 문제: 
     - Sign in with Apple 로그인 시 오류 메시지 표시
     - 푸시 알림에서 '나중에' 탭 시 앱 멈춤
   - 해결 방안:
     - 지원되는 기기에서 철저한 테스트 진행
     - Sign in with Apple 기능 오류 수정
     - 푸시 알림 관련 버그 수정

3. 스크린샷 부적절 (Guideline 2.3.3):
   - 문제: 제공된 스크린샷이 앱의 실제 사용을 충분히 보여주지 않음
   - 해결 방안:
     - 앱의 주요 기능과 UI를 보여주는 새로운 스크린샷 업로드
     - iPad Pro와 13인치 iPad 스크린샷에 iPhone 이미지를 확대한 것이 아닌 실제 iPad 화면 사용

4. 테스트 광고 포함 (Guideline 2.5.10):
   - 문제: 앱이나 메타데이터에 테스트 광고 포함
   - 해결 방안: 테스트나 데모용 기능 제거 또는 완전히 구현

5. Sign in with Apple 디자인 가이드라인 미준수 (Guideline 4.0):
   - 문제: Apple 로고를 Sign in with Apple 버튼으로 사용할 경우 텍스트가 없어야 함
   - 해결 방안: Sign in with Apple 버튼 디자인 수정

이러한 문제들을 해결하고 앱을 개선한 후 다시 제출하면 승인 가능성이 높아질 것입니다. 각 가이드라인에 대한 자세한 내용은 Apple의 개발자 문서를 참조하시기 바랍니다.


flutter pub run flutter_native_splash:remove
flutter pub run flutter_native_splash:create



# 구글스토어 목업 탬플릿
https://studio.app-mockup.com/