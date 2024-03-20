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



            



       
  


