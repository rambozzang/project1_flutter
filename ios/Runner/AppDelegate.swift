import Flutter
import UIKit
// import NaverThirdPartyLogin



@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  // override func application(
  //   _ application: UIApplication,
  //   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  // ) -> Bool {
  //   GeneratedPluginRegistrant.register(with: self)
  //   return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  // }


    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      // fcm 으로 추가
      // FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      //     GeneratedPluginRegistrant.register(with: registry)
      // }
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }


  // override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
  //     var applicationResult = false
  //     if (!applicationResult) {
  //       applicationResult = NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)
  //     }
    

  //     // fcm 으로 추가
  //     FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
  //         GeneratedPluginRegistrant.register(with: registry)
  //     }
  //     if #available(iOS 10.0, *) {
  //       UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  //     }
      
  //     if (!applicationResult) {
  //       applicationResult = super.application(app, open: url, options: options)
  //     }
  //     return applicationResult
  // }
}
  

