//
//  AppDelegate.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/23/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import Firebase
import DropDown
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Register for Local Notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
        center.delegate = self
        
        
        // Setup Firebase
        FIRApp.configure()
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            guard error == nil else {
                print("Error Authenticating User. Error: \(error?.localizedDescription)")
                return
            }
            let id = user?.uid ?? "No ID"
            FIRDatabase.database().reference(withPath: "users/\(id)").keepSynced(true)
        })
        FIRDatabase.database().persistenceEnabled = true
        
        styleNavBar()
        // Setup DropDown
        DropDown.startListeningToKeyboard()
        return true
    }
    
    func styleNavBar(){
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.barTintColor = UIColor(colorLiteralRed: 5/255, green: 170/255, blue: 25/255, alpha: 1)
        navBarAppearance.tintColor = UIColor.white
        navBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navBarAppearance.barStyle = .black
        UINavigationBar.appearance()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func handleNotification(forEmailInfo emailInfo: EmailInfo){
        guard let viewController = window?.rootViewController?.contentViewController else {
            print("Couldn't get view controller")
            return
        }
        
        var message = "It's time to send the notification for \(emailInfo["name"]!)!"
        if viewController.presentedViewController != nil {
            print("Email View!")
            message += " Go back to the main screen to send it."
        }
        let alert = UIAlertController(title: "Email Reminder", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        (viewController.presentedViewController ?? viewController).present(alert, animated: true, completion: nil)
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
        guard let emailInfo = response.notification.request.content.userInfo as? EmailInfo else {
            completionHandler()
            return
        }
        
        if let mailVC = window?.rootViewController?.contentViewController as? MailSwipeViewController {
            if mailVC.presentedViewController != nil {
                mailVC.dismiss(animated: true, completion: {
                    mailVC.openEmailEditor(forEmailInfo: emailInfo)
                })
            }else {
                mailVC.openEmailEditor(forEmailInfo: emailInfo)
            }
        }else {
            let mailVC = UIStoryboard(name: "main", bundle: nil).instantiateInitialViewController()?.contentViewController as! MailSwipeViewController
            window?.rootViewController = mailVC
            mailVC.openEmailEditor(forEmailInfo: emailInfo)
        }
        completionHandler()
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
        
        guard let emailInfo = notification.request.content.userInfo as? EmailInfo else {
            completionHandler([])
            return
        }
        handleNotification(forEmailInfo: emailInfo)
        completionHandler([])
        
    }

    
   
}

