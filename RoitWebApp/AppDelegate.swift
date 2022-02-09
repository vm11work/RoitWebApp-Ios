import UIKit
import Firebase
//import FirebaseMessaging
//import UserNotifications
import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var token : String = "토큰"
    var push_url : String = "푸시 url"
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //파이어베이스 설정.
        FirebaseApp.configure()

        //원격 알림 등록.
        if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self
          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
          )
        }

        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        //푸시 포그라운드 설정.
        UNUserNotificationCenter.current().delegate=self
        return true;
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

}
extension AppDelegate : MessagingDelegate
{
    //fcm 등록 토큰을 받았을때.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        token = fcmToken!
     
        print("AppDelegate - Firebase registration token: \(String(describing: fcmToken))")
        
        
        
    }
}


extension AppDelegate : UNUserNotificationCenterDelegate
{
    //푸시메시지가 앱이 켜진상태에서 나올때.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        let userInfo = notification.request.content.userInfo
        completionHandler([.banner, .sound, .badge])
    }
    
    //푸시메시지를 클릭했을 때.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            let userInfo = response.notification.request.content.userInfo
        
//        url정보가 변경된 것을 contentview 에서 처리해주기. 
//        ContentView.ur
        push_url = "푸시 didRecieve"
        print("푸시 didRecieve : userinfo", userInfo)
        completionHandler()
    }
    
}
