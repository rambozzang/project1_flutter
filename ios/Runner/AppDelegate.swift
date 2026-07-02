import Flutter
import UIKit
import AVFoundation
// import NaverThirdPartyLogin
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // 카메라 가상 멀티카메라(초광각 포함) 조회 채널 — 0.5x 줌아웃용.
        // camerawesome은 기본으로 광각 단일 렌즈만 쓰므로, 트리플/듀얼와이드 가상 디바이스의
        // uniqueID와 렌즈 전환 팩터(switchOver)를 Dart에 넘겨 setSensorType으로 전환하게 한다.
        if let controller = window?.rootViewController as? FlutterViewController {
            let lensChannel = FlutterMethodChannel(
                name: "com.skysnap/camera_lens",
                binaryMessenger: controller.binaryMessenger)
            lensChannel.setMethodCallHandler { call, result in
                guard call.method == "getVirtualBackCamera" else {
                    result(FlutterMethodNotImplemented)
                    return
                }
                let discovery = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInTripleCamera, .builtInDualWideCamera],
                    mediaType: .video,
                    position: .back)
                guard let device = discovery.devices.first else {
                    result(nil)
                    return
                }
                let switchOvers = device.virtualDeviceSwitchOverVideoZoomFactors.map { Double(truncating: $0) }
                result(["uid": device.uniqueID, "switchOver": switchOvers])
            }
        }

        // FCM 설정
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        // NaverThirdPartyLoginConnection.getSharedInstance().isInAppOauthEnable = true
        // NaverThirdPartyLoginConnection.getSharedInstance().isNaverAppOauthEnable = true

        //     // 네이버 로그인 설정
        // let instance = NaverThirdPartyLoginConnection.getSharedInstance()     
        // instance?.serviceUrlScheme =  "com.codelabtiger.skysnap" // 앱을 등록할 때 입력한 URL Scheme
        // instance?.consumerKey = "iC9RuDfC4wmdwHXS02Sa" // 애플리케이션에서 사용하는 클라이언트 아이디
        // instance?.consumerSecret = "VYG6_hVGkl" // 애플리케이션에서 사용하는 클라이언트 시크릿
        // instance?.appName = "SkySnap"// 애플리케이션 이름



        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // URL 처리를 위한 메서드
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var applicationResult = false
        // if(!applicationResult){
        //     applicationResult = NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
        // }
        if(!applicationResult){
            applicationResult = super.application(app, open: url, options: options)
        }
        return applicationResult
    }
}


// import Flutter
// import UIKit
// // import NaverThirdPartyLogin
// import flutter_local_notifications


// @UIApplicationMain
// @objc class AppDelegate: FlutterAppDelegate {
//   // 원본 내용
//   // override func application(
//   //   _ application: UIApplication,
//   //   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   // ) -> Bool {
//   //   GeneratedPluginRegistrant.register(with: self)
//   //   return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   // }

//     override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
    
//     // FCM 설정. 
//     FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
//         GeneratedPluginRegistrant.register(with: registry)
//     }

//     if #available(iOS 10.0, *) {
//       UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
//     }

//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }
  

