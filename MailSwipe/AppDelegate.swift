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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate{

    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        // Register for Local Notifications
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        print("Application Did Finish Launching")
        // Setup Firebase
        FIRApp.configure()
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            guard error == nil else {
                print("ERROR AUTHENTICATING USER. Error: \(error!.localizedDescription)")
                return
            }
            
            let id = user?.uid ?? "No ID"
            print("USER ID: \(id)")
            FIRDatabase.database().reference(withPath: "users/\(id)").keepSynced(true)
            NotificationCenter.default.post(Notification(name: Notification.Name(Constants.UserAuthenticatedNotification)))
        })
        FIRDatabase.database().persistenceEnabled = true
        
        styleNavBar()
        // Setup DropDown
        DropDown.startListeningToKeyboard()

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
    

    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("Did recieve notification")
        guard let emailInfo = notification.userInfo?["email"] as? EmailInfo else { return }
        
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

    }
   
}

