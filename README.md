# project1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## firbase 설정
 1. firebase 사용 설정
  1) firebase 설치  
    #] curl -sL https://firebase.tools | bash 
    #] dart pub global activate flutterfire_cli
  2) 프로젝트 폴더에서 firebase 로그인 처리
    #] firebase login
  3) 프로젝트 리스트로 확인
    #] firebase projects:list
  4) .zshrc 파일에 어래 패스 추가
     export PATH="$PATH":"$HOME/.pub-cache/bin"  
  5) 프로젝트 설정을 연결
    #] flutterfire configure --project=project1-c07d1   

## google_sign_in 패키지 로그인 구현
 - flutter 에서 구글 로그인 및 firebase 사용자 생성까지 가능하여 백엔드에서는 회원테이블에 생성만한다.
   (네이버,카카오는 백엔드에서 firebase 및 회원정보 테이블 생성을 담당)
 - https://velog.io/@qazws78941/FlutterGoogle-Login-%EA%B5%AC%ED%98%84
 - https://github.com/flutter/packages/tree/main/packages/google_sign_in/google_sign_in

 1. 구글 클라우드에 프로젝트를 등록
  - https://console.cloud.google.com/apis/dashboard?project=auth-common-375905
 2. 신규 프로젝트 생성
 3. 왼쪽메뉴 > Oauth 동의 화면 
   - 동의화면 완성
   - 범위에서는 아래의 3가지 범위
     -> 민감하지 않은 범위 : 
        openid(Google에서 내 개인 정보를 나와연결) , 
        People Api (기본 google계정의 이메일주소확인) , 
        People Api (개인정(공개로 설정한 개인정포함) 보기)

 4. 왼쪽메뉴 > 사용자 인증 정보
    - 사용자 인증 어보 만들기 
      1) API 키 AIzaSyBLQ9xAd9rxORs020B_arpj47cWdq0FKkI   -> 안만들어도 되는거 같다.
      2) Oauth 클라이언트 ID
        A .android 패키지명 > com.tigerbk.project1
           sha-1이증서 디지털 지문
            -> keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
            -> sha1 라인 코드를 복사해서 입력하면 된다.
           클라이언트 ID : 638945890094-i0lf77fpgmqjtam25u8p08v32k274i8b.apps.googleusercontent.com
            -> json 다운 받아 저장킵   

        B .ios 설정   
         번들Id는 Xcode 를 통해 확인
         App Store Id 생량(앱스토어 배포하지 않았으므로 )
         팀ID : Developer 등록툄 팀ID 입력
         클라이언트 ID : 638945890094-2q5u2fvl7mvro889jn57g5vva44r6gob.apps.googleusercontent.com
         -> json 다운 받아 저장킵   
        C. web 설정
         
 5. firebase 웹콘설 프로젝트 설정 에서 android/ios json 파일 download
   - android : /android/app/google-services.json
   - ios : /ios/Runner/infoplist 

## kakao 패키지 로그인 구현
https://devtalk.kakao.com/t/koe009-invalid-android-key-hash-or-ios-bundle-id-or-web-site-url/131520

1.앱사용 등록
    https://developers.kakao.com/console/app/1049247/config/platform 

2.앱 사용 등록시 조회 항목 재정의 필요 추후예정    

## Naver 패키지 로그인 구현
1.앱사용으로 별다른 셋팅없이 구현가능



            



       
  


## TOBE

댓글 기능
 https://velog.io/@locked/Flutter-%EC%9C%A0%ED%8A%9C%EB%B8%8C-%EB%8B%B5%EA%B8%80-%EA%B8%B0%EB%8A%A5-%EB%A7%8C%EB%93%A4%EA%B8%B0



## 불법영상 검거 방법
 - awa rekongnition
  https://aws.amazon.com/ko/rekognition/pricing/?nc=sn&loc=4

 - flutter_node_detector 패키지
 - https://huggingface.co/Falconsai/nsfw_image_deection

#카메라 변경
camerawesome: ^2.0.1

#video play 변경
 - chewie
    ->https://github.com/fluttercommunity/chewie



1. 회원정보 수정
  - 회원 정보 조회 서비스
  - 이름 / 자기소개 / 뽀송ID 3개 수정 서비스
  - 프로필 파일 수정 서비스 


2. 팔로워 리스트 팔로위 리스트 - 회정정보 리스트 조회

3. 다른 사람 회원 정보 조회 화면

4. CCTV Api 
https://padro.tistory.com/171

담당자 : 허재영(도시교통정보센터) j1008@naver.com
CCTV 데이터 URL - http://www.utic.go.kr/guide/cctvOpenData.do?key=인증키
[VI6l9pfWdIclwcZP3Go7orBQKYcp2jKs3AtbfXuAOsQOZ3bZmgpdQ9AJ0AM4fEfmJKYyLlSmhLFLWRRrIwg]
(https://www.utic.go.kr/guide/cctvOpenData.do?key=sVI6l9pfWdIclwcZP3Go7orBQKYcp2jKs3AtbfXuAOsQOZ3bZmgpdQ9AJ0AM4fEfmJKYyLlSmhLFLWRRrIwg)


https://www.utic.go.kr/view/map/openDataCctvStream.jsp?key=sVI6l9pfWdIclwcZP3Go7orBQKYcp2jKs3AtbfXuAOsQOZ3bZmgpdQ9AJ0AM4fEfmJKYyLlSmhLFLWRRrIwg&cctvid=L933103&cctvName=%25EA%25B0%2595%25EC%259B%2590%2520%25EA%25B0%2595%25EB%25A6%2589%2520%25EC%25A3%25BC%25EB%25AC%25B8%25EC%25A7%2584%25EB%25B0%25A9%25ED%258C%258C%25EC%25A0%259C&kind=KB&cctvip=9995&cctvch=null&id=null&cctvpasswd=null&cctvport=null


5. android 사이즈 apk 파일 줄이기
https://github.com/google/bundletool/issues/155

 android:extractNativeLibs="true" 또는

android {
  packagingOptions {
    jniLibs {
      useLegacyPackaging true
    }
  }
}

6. Navigator.pop(context) 변경
 -> 
  if(!context.mounted) return;
  Navigator.pop(context);
  

 7. android impellar video player 안되는 문제
  -> https://github.com/flutter/packages/pull/6456 

  /.pub-cache/hosted/pub.dev/video_player_android-2.4.14/android/src/main/java/io/flutter/plugins/videoplayer  vi VideoPlayer.java
  189 라인 수정
  

  8. 이쁜 컨테이너
  Container(
    decoration : BoxDecoration(
      gradient : LinearGradient(
        color :[
          Color.fromARGB(255,21,85,169),
          Color.fromARGB(255,44,162,246),

        ]
      )
    )
  )

  7 날씨 아이콘
  https://basmilius.github.io/weather-icons/index-fill.html

  아이콘 변경
  https://peter-codinglife.tistory.com/70


  8. 오픈 초기 동영상이 부족할때 아래에서 가져온다 ( 이미지, 동영상 모두 무료)
   https://www.pexels.com/ko-kr/search/videos/%ED%9D%B0%EA%B5%AC%EB%A6%84/


g

   9 supabase Db passwd : GsH1yDz1ZytaChAS
   Creating project:    skysnap-chat
  Selected org-id:     lzonmptiklzcsgkuyuox
  Selected region:     ap-northeast-2
   REFERENCE ID     : wtyeuynrapbgtpquxxfm

Selected project: wtyeuynrapbgtpquxxfm
    ───────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    anon         │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eWV1eW5yYXBiZ3RwcXV4eGZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc1NTM4NzYsImV4cCI6MjAzMzEyOTg3Nn0.RZKF6Nfkqr7fA7Uc7RtZc_Jnl4zw_Q6iDV-5J9DfIM8
    service_role │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eWV1eW5yYXBiZ3RwcXV4eGZtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxNzU1Mzg3NiwiZXhwIjoyMDMzMTI5ODc2fQ.Eq9HKyTCAjOCAmZdvWe83M-KZRAsfoJOFqISnssmLa4

