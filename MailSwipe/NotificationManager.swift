//
//  NotificationManager.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 9/1/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationManager {
    
    
    
    class func scheduleEmailNotifications(forEmail email: Email, withName name: String, withDate date: Date){
        
        var newIdentifier = "\(email.id)-\(String.randomStringWithLength(length: 5))"
        if let existingIdentifier = UserDefaults.standard.object(forKey: email.id) as? String {
            print("Existing Identifier: \(existingIdentifier)")
            for notification in UIApplication.shared.scheduledLocalNotifications ?? [] {
                guard let id = notification.userInfo?["id"] as? String else { continue }
                if id == existingIdentifier {
                    print("Cancelling Notification with Identifier: \(id)")
                    UIApplication.shared.cancelLocalNotification(notification)
                }
            }
            while (existingIdentifier == newIdentifier) {
                newIdentifier = "\(email.id)-\(String.randomStringWithLength(length: 5))"
            }
        }
        UserDefaults.standard.set(newIdentifier, forKey: email.id)
    
        let calendar = Calendar.current
        let curYear = calendar.component(.year, from: Date())
        let setDay = calendar.component(.day, from: date)
        var timeComponents = calendar.dateComponents([.hour, .minute, .second, .day, .month], from: date)
        timeComponents.year = curYear
        timeComponents.day = setDay - 1
        
        let adjustedDate = calendar.date(from: timeComponents)
        let repeatInterval = email.info["repeatInterval"] as? String ?? "Weekly"

        print("Adjusted Date by setting year \(adjustedDate)")
        // create a corresponding local notification
        let notification = UILocalNotification()
        if #available(iOS 8.2, *) {
            notification.alertTitle = "\(name) Tomorrow"
        }
        notification.alertBody = "Swipe to send your \(name) email!"
        notification.alertAction = "Send"
        notification.fireDate = adjustedDate // todo item due date (when notification will be fired)
        print("\(name) will be fired \(adjustedDate)")
        switch repeatInterval {
            case "Monthly": notification.repeatInterval = .month
            case "Once" : break //No Repeat Interval
            default: notification.repeatInterval = .weekOfYear
        }
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber + 1
        notification.userInfo = ["id": newIdentifier, "email" : email.info] // assign a unique identifier to the notification so that we can retrieve it later
        
        UIApplication.shared.scheduleLocalNotification(notification)

    }

}
