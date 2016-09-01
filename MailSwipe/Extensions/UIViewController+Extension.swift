//
//  UIViewController+Extension.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 9/1/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var contentViewController : UIViewController {
        if let navController = self as? UINavigationController {
            return navController.viewControllers.last?.contentViewController ?? self
        }
        return self
    }
}
