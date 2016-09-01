//
//  Date+Extension.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/31/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import Foundation

extension Date {
    
    private static var dateFormatter = DateFormatter()
    
    static func getDate(fromReadableString string: String) -> Date? {
        dateFormatter.dateFormat = "EEEE – hh:mm a"
        return dateFormatter.date(from: string)
    }
    
    static func getDate(fromServerString string: String) -> Date? {
        dateFormatter.dateFormat = "EEE - MM-dd - hh:mma"
        return dateFormatter.date(from: string)
    }
    
    func getReadableString() -> String {
        Date.dateFormatter.dateFormat = "EEEE – hh:mm a"
        return Date.dateFormatter.string(from: self)
    }
    
    func getServerString() -> String {
        Date.dateFormatter.dateFormat = "EEE - MM-dd - hh:mma"
        return Date.dateFormatter.string(from: self)
    }
    
    var basicDateString : String {
        Date.dateFormatter.dateFormat = "MM-dd-yyyy hh:mma"
        return Date.dateFormatter.string(from: self)
    }
    
}
