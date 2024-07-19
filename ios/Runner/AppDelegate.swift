import Flutter
import UIKit
import NaverThirdPartyLogin
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // FCM 설정
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        // 네이버 로그인 설정
        let instance = NaverThirdPartyLoginConnection.getSharedInstance()
        instance?.isNaverAppOauthEnable = true  // 네이버 앱으로 인증하는 방식을 활성화
        instance?.isInAppOauthEnable = true     // Safari 등 외부 브라우저로 인증하는 방식을 활성화

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // URL 처리를 위한 메서드
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options) {
            return true
        }
        return super.application(app, open: url, options: options)
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
  

