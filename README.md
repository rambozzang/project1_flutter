# SkySnap App by CodeLabtiger

앱스크린샷
https://www.figma.com/design/J1jTkl6TLwbkXPDi6bzbrx/App-Store-Screenshot-Template-(Community)?node-id=6-2274&node-type=frame&t=o2ho2Bx82if4fXTS-0


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
 3. 안드로이드 디버그 기호 파일 업로드
 cleanZip.sh 파일 실행 후 
 ~/work/app/flutter/project1/build/app/intermediates/merged_native_libs/release/out/lib 폴더에서 zip 업로드
 
 
**app/build/app/intermediates/merged_nativ_libs/프로젝트폴더/out/lib**
- x86_64
- x86
- armeabi-v7a
- arm64-v8a

4개 폴더 모두 압축

압축 폴더 안에 **__MACOSX**, **.DS_Store**를 포함하면 안됨.

### **폴더 안에서 아래 명령어로 삭제 해준다.** (MAC에서 마우스 우측 클릭으로 압축하면 안됨 터미널 이용!)

https://hooun.tistory.com/432

cd ~/work/app/flutter/project1/build/app/intermediates/merged_native_libs/release/out/lib

find . -name "__MACOSX" -exec rm -rf {} +
find . -name ".DS_Store" -exec rm -rf {} +
zip -r ../symbols_clean.zip ./*

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

# 밤과 낮 애니메이션
https://github.com/abuanwar072/Flutter-Day-and-Night-Mood-Animation?tab=readme-ov-file

#앱스토어 이미지 등록
https://www.figma.com/design/J1jTkl6TLwbkXPDi6bzbrx/App-Store-Screenshot-Template-(Community)?node-id=6-2358&node-type=FRAME&t=yaTUNn8kjfP1xE2n-0

https://www.figma.com/community/plugin/1305891870034170272/imockup


20240910 수정사항
 - 사용자정보 조회 스와이프 방향 수정
 - 알람 리스트 와 대화하기 리스트 데이터없음 표시 수정
 - 위치권한 설정 이후 프로세스 진행하도록 수정.
 - 비디오 리스트 팔로우 조회 오류 수정
 - 데이터 없을때 로직 추가 - 전체조회버튼 추가
 - 24시 온도 그래프 간격 조정


 20230919 수정사항
  - 안드로이드인경우 Dash 비디오 포멧 이용

 20230921 수정사항
  - 날씨가져오기에서 어제 날씨 중복제거 로직 수정
  - 프로필사진 수정


### 네이버 로그인 오류 아래 네이버 패키지 소스 들어가서 수정하고 빌드해야함
# flutter_naver_login.podspec' 4.2.3 버전으로 변경 





# 구글플레이 aab 업로드 오류 '1 버전 코드는 이미 사용되었습니다. 다른 버전 코드를 사용해 보세요.]
-> build.gradle 버전 코드 수정 flutterVersionCode , flutterVersionName 을 하나씩 증가 시키면 됨.
해결방법
1. pubspec.yaml 
##version: 1.0.0+1 	//이전 버전
version: 1.0.1+2	//수정된 버전
1.0.1은 수정되는 버전이고 +2는 2번째 수정이라는 의미이다.
2. android/app/build.gradle
def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '2' //버전업 횟수 
}
def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0.1' //수정되는 버전
}
 
3. android/local.properties
flutter.versionName=1.0.1 //수정되는 버전
flutter.versionCode=2	//버전업 횟수
 


 안녕하세요.
 기상청 시스템 장애으로 인해 서비스가 중단된상태입니다.
 현재 기상청에서  언제 완료될지 고지된 사항은 없습니다.

 불편함 없이 서비스를 지속적으로 이용하실 수 있도록 최선을 다하겠습니다. 
 감사합니다.

 # 스크롤시 appbar 색상 변경 :  scrolledUnderElevation: 0,

 # 구형폰에서 안드 백버튼 popscape 가 안먹히는 문제 : android:enableOnBackInvokedCallback="false"  추가 



안녕하세요 플러터로 앱 개발 열심히 하고 있는 노가다 개발자입니다!

본업은 백엔드개발자인데 혼자서 이것저것 다 붙여봤습니다. ㅎㅎ
틱톡+날씨 앱이라고 보시면 됩니다. 영상쪽 참 어렵더군요. 앱이 시도때도 없이 메모리로 죽어버렸었고요.
이제 좀 안정화된거 같아요.

- 서비스명 : SkySnap
- 앱 스토어 : https://apps.apple.com/kr/app/%EC%8A%A4%EC%B9%B4%EC%9D%B4%EC%8A%A4%EB%83%85-skysnap/id6557075398
- 플레이 스토어 : https://play.google.com/store/apps/details?id=com.codelabtiger.skysnap&hl=ko
- 버그 리포트 및 피드백 : 각 리뷰에다가 올려주세요.

이앱은 날씨예보와 실시간 영상을 공유하는 앱입니다.
기상청 날씨예보로는 불안하시잖아요. 먼저 출근하는 동료한테 진짜 비오냐?  눈오냐? 물어볼수도 없구요.
출근(등교)시  2초정도 영상 올려주시면 같은곳으로 출근,등교하는 많은 동료들이 날씨예측하는데 도움이 됩니다.

주말에는 야구장,골프장,놀이동산, 낚시, 캠피장 날씨 영상도 올려주시구요. 콘서트장 데이트장소,주말행사 등등 날씨도 마찬가지구요
커뮤니티도 만들어놨습니다. 마구마구 글좀 남겨주세요.

개발은 flutter + springboot3.2 jpa jdk21 + Jenkins + github + mariadb + cafe24cloud + cloudflare + vscode(or cursor) + intellij + tabby 사용중입니다.
flutter 상태관리는 rxdart 와 getx 로 되어 있습니다.  테이블은 15개정도 만들어졋네요.

개발기간은 5개월정도 걸렸습니다. 카메라,비디오플레이어때문에 한두달은 그냥 까먹었어요.ㅠㅠ

서버비용은 월 6만원정도(카페24클라우드 4,3 , cloudflare 2.0 ) 나오고 있습니다. 외국 날씨api는 프리 용량까지만 사용가능합니다. 돈이 없어요 ㅎ

아 그리고 채팅도 있는데 supabase 로 구현되어 있는데요 음....... 뭐 리얼타임db 딱 그정도에요.
빠르게 채팅도 소켓으로 변경 할 예정입니다. 좋은 소스 있으시면 공유좀~  

수익모델은 admob 입니다.  

추후 서버비 감당이 안되면 서비스 내릴수도 있습니다.

아 그리고 관리자도 flutter 로 개발중입니다.

현재 가입자수 79명(앱심사자들이 한 30명 된는거 같아요 심사올릴때마다 회원가입이 늘어요 ㅎㅎ) 

한번씩만 사용해봐 주시고 질문도 댓글도 많이많이 남겨주세요!!
