//
//  KeyboardListener.swift
//  DropDown
//
//  Created by Kevin Hirsch on 30/07/15.
//  Copyright (c) 2015 Kevin Hirsch. All rights reserved.
//

import UIKit

internal final class KeyboardListener {
	
	static let sharedInstance = KeyboardListener()
	
	private(set) var isVisible = false
	private(set) var keyboardFrame = CGRect.zero
	private var isListening = false
	
	deinit {
		stopListeningToKeyboard()
	}
	
}

//MARK: - Notifications

extension KeyboardListener {
	
	func startListeningToKeyboard() {
		if isListening {
			return
		}
		
		isListening = true
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(keyboardWillShow(_:)),
			name: NSNotification.Name.UIKeyboardWillShow,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(keyboardWillHide(_:)),
			name: NSNotification.Name.UIKeyboardWillHide,
			object: nil)
	}
	
	func stopListeningToKeyboard() {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc
	private func keyboardWillShow(_ notification: Notification) {
		isVisible = true
		keyboardFrame = keyboardFrameFromNotification(notification)
	}
	
	@objc
	private func keyboardWillHide(_ notification: Notification) {
		isVisible = false
		keyboardFrame = keyboardFrameFromNotification(notification)
	}
	
	private func keyboardFrameFromNotification(_ notification: Notification) -> CGRect {
		return ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
	}
	
}
