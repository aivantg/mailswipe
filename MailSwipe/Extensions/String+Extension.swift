//
//  String+Extension.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/23/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import Foundation

extension String
{
    func removeSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var containsText : Bool {
        get {
            return !isEmpty
        }
    }
}
