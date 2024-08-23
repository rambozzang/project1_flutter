# SkySnap App by CodeLabtiger

이 프로젝트에 대한 자세한 정보는 개발 팀에 문의하세요.

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

`/work/app/flutter/project1/build/app/intermediates/merged_native_libs/release/out/lib` 

- find . -name "__MACOSX" -exec rm -rf {} +
- find . -name ".DS_Store" -exec rm -rf {} +
- zip -r ../symbols_clean.zip ./*

symbols_clean.zip  파일 업로드 끝!!