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
    
    static func randomStringWithLength (length : Int) -> String {
        
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in (0..<length) {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let newCharacter = allowedChars[allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)]
            randomString += String(newCharacter)
        }
        
        return randomString
    }
    
    func extractEmails() -> [String] {
        let pattern = "([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.[a-zA-Z0-9._-]+)"
        var results = [String]()

        do {
            
            let regexp = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            regexp.enumerateMatches(in: self, options: .withTransparentBounds, range: NSRange(location: 0, length: self.characters.count), using: { (result, _, _) in
                guard let result = result else{ return }
                results.append((self as NSString).substring(with: result.range))

            })
        }catch { }
        return results
    }
}
