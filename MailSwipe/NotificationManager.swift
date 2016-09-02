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
    
    func scheduleEmailNotifications(forEmail email: Email, withName name: String, withDate date: Date){
        
        let center = UNUserNotificationCenter.current()
        var newIdentifier = "\(email.id)-\(String.randomStringWithLength(length: 5))"
        if let existingIdentifier = UserDefaults.standard.object(forKey: email.id) as? String {
            center.removePendingNotificationRequests(withIdentifiers: [existingIdentifier])
            center.removeDeliveredNotifications(withIdentifiers: [existingIdentifier])
            while (existingIdentifier == newIdentifier) {
                newIdentifier = "\(email.id)-\(String.randomStringWithLength(length: 5))"
            }
        }
        UserDefaults.standard.set(newIdentifier, forKey: email.id)
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "\(name) Tomorrow"
        notificationContent.body = "Swipe to send your \(name) email!"
        notificationContent.userInfo = email.info
        notificationContent.sound = UNNotificationSound.default()
        notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1
        
        let calendar = Calendar.current
        var minusDayComponent = DateComponents()
        minusDayComponent.day = -1
        let adjustedDate = calendar.date(byAdding: minusDayComponent, to: date)
        let repeatInterval = email.info["repeatInterval"] as? String ?? "Weekly"
        var repeatComponents = DateComponents()
        let selectedComponents = calendar.dateComponents([.hour, .minute, .weekday, .weekOfMonth], from: adjustedDate!)
        repeatComponents.weekday = selectedComponents.weekday
        repeatComponents.hour = selectedComponents.hour
        repeatComponents.minute = selectedComponents.minute
        if repeatInterval == RemindInterval.monthly.rawValue {
            repeatComponents.weekOfMonth = selectedComponents.weekOfMonth
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: repeatComponents, repeats: true)
        
        let emailRequest = UNNotificationRequest(identifier: newIdentifier, content: notificationContent, trigger: trigger)
        UNUserNotificationCenter.current().add(emailRequest) { (error) in
            // handle the error if needed
            print(error)
        }
    }

}
