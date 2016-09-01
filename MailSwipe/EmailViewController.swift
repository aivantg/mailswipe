//
//  NewEmailViewController.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/24/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import DropDown
import Firebase
import UserNotifications

enum RemindInterval : String {
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    static func getAll() -> [String]{
        return ["Weekly", "Monthly"]
    }
}

class EmailViewController: UIViewController {
    
    var existingEmail : Email?
    
    var selectedDate : Date?
    
    @IBOutlet weak var bodyTextViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameTextField: UITextField! {
        didSet{
            nameTextField.delegate = self
            nameTextField.tag = 1
        }
    }
    @IBOutlet weak var dateTextField: UITextField! {
        didSet{
            dateTextField.delegate = self
            dateTextField.tag = 2
            
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .dateAndTime
            datePicker.date = Date.getDate(fromServerString: (existingEmail?.info["date"] as? String) ?? "") ?? Date()
            datePicker.addTarget(self, action: #selector(updateMeetingTimeText(sender:)), for: .valueChanged)
            
            let doneToolbar = UIToolbar()
            doneToolbar.barStyle = .default
            doneToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(finishDatePicker))]
            doneToolbar.sizeToFit()
            dateTextField.inputAccessoryView = doneToolbar
            dateTextField.inputView = datePicker
        }
    }
    @IBOutlet weak var recipientTextField: UITextField!{
        didSet{
            recipientTextField.delegate = self
            recipientTextField.tag = 4
        }
    }
    @IBOutlet weak var locationTextField: UITextField!{
        didSet{
            locationTextField.delegate = self
            locationTextField.tag = 3
        }
    }
    @IBOutlet weak var bodyTextView: UITextView!{
        didSet{
            bodyTextView.tag = 5
            bodyTextView.delegate = self
            
            let doneToolbar = UIToolbar()
            doneToolbar.barStyle = .default
            doneToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(finishBodyTextView))]
            doneToolbar.sizeToFit()
            bodyTextView.inputAccessoryView = doneToolbar
        }
    }
    @IBOutlet weak var repeatButton: NiceButton!
    
    var keyboardHeight : CGFloat = 0
    var keyboardAnimationDuration : Double = 0.1

    let repeatDropdown = DropDown()
    
    
    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.becomeFirstResponder()
        

        updateBodyTextViewText()
        setupDropDown()
        checkExistingEmail()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: Notification.Name.UIKeyboardDidShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardDidShow(notification: Notification){
        keyboardHeight = CGFloat((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 8)
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) ?? 0.1
        print("Found Keyboard Height: \(keyboardHeight)")
        
    }
    
    //MARK: - Firebase Saving
    
    @IBAction func saveEmail(_ sender: AnyObject) {
        guard let email = getEmail() else { showUnfinishedAlert(); return }
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            showUnfinishedAlert(withTitle: "Error", withMessage: "Unable to save email :( Try restarting the app!")
            return
        }
        let emailId = existingEmail != nil ? existingEmail!.id : email.id
        let ref = FIRDatabase.database().reference().child("users/\(uid)/\(emailId)")
        ref.setValue(email.info)
        showAlert(title: "Reminders Scheduled!", message: "MailSwipe will now send you a notification 24 hours before the club meeting reminding you to send your email!", action: {
            self.scheduleNotifications(forEmail: email, withName: email.info["name"]! as! String, withDate: self.selectedDate!)
            self.presentingViewController?.dismiss(animated: true, completion: nil)

        })
    }
    
    func scheduleNotifications(forEmail email: Email, withName name: String, withDate date: Date){
        
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
        notificationContent.title = "MailSwipe"
        notificationContent.body = "Swipe to send your \(name) email!"
        notificationContent.userInfo = email.info
        notificationContent.categoryIdentifier = "email"
        
        
        let calendar = Calendar.current
        var repeatComponents = DateComponents()
        var minusDayComponent = DateComponents()
        minusDayComponent.day = -1
        let adjustedDate = calendar.date(byAdding: minusDayComponent, to: date)
        let selectedComponents = calendar.dateComponents([.hour, .minute, .weekday, .weekOfMonth], from: adjustedDate!)
        repeatComponents.weekday = selectedComponents.weekday
        repeatComponents.hour = selectedComponents.hour
        repeatComponents.minute = selectedComponents.minute
        if repeatButton.titleLabel?.text == RemindInterval.monthly.rawValue {
            repeatComponents.weekOfMonth = selectedComponents.weekOfMonth
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: repeatComponents, repeats: true)
        
        let emailRequest = UNNotificationRequest(identifier: newIdentifier, content: notificationContent, trigger: trigger)
        UNUserNotificationCenter.current().add(emailRequest) { (error) in
            // handle the error if needed
            print(error)
        }
    }
    
    func getEmail() -> Email? {
        let name = nameTextField.text?.trim() ?? ""
        let location = locationTextField.text?.trim() ?? ""
        let repeatInterval = repeatButton.titleLabel?.text ?? ""
        let body = bodyTextView.text.trim() ?? ""
        let recipientText = recipientTextField.text?.trim() ?? ""
        
        guard
            name.containsText,
            location.containsText,
            repeatInterval.containsText,
            body.containsText,
            recipientText.containsText,
            let date = selectedDate
        else {
            showUnfinishedAlert()
            return nil
        }
        
        var recipients = recipientText.components(separatedBy: ",").map() { $0.trim() }
        guard recipients.count > 0 else { showUnfinishedAlert(); return nil }
        recipients = recipients.filter { (email) -> Bool in
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: email)
        }
        guard recipients.count > 0 else {
            showAlert(title: "Invalid Email Address", message: "You must enter at least one valid email address.")
            return nil
        }
        
        return (id: name.removeSpaces(), info: ["name" : name, "location" : location, "repeatInterval" : repeatInterval, "body" : body, "recipients" : recipients, "date" : date.getServerString()])
    }
    
        func showUnfinishedAlert(withTitle title: String? = nil, withMessage message: String? = nil){
        let alert = UIAlertController(title: title ?? "Fill Out Every Field", message: message ?? "Please fill out all the fields in order to continue.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    
    //MARK: - UI Actions
    
    func cancelEmail(){
        performSegue(withIdentifier: "Exit Segue", sender: nil)
    }

    @IBAction func importEmails(_ sender: AnyObject) {
        let googleSheetsUrl = URL(string: "googlesheets://")!
        let googleDriveUrl = URL(string: "googledrive://")!
        if UIApplication.shared.canOpenURL(googleSheetsUrl) {
            UIApplication.shared.open(googleSheetsUrl, options: [:], completionHandler: nil)
        }else if UIApplication.shared.canOpenURL(googleDriveUrl) {
            UIApplication.shared.open(googleDriveUrl, options: [:], completionHandler: nil)
        }else {
            showAlert(title: "Unable to Import", message: "You must install either the Google Drive app or the Google Sheets app to import.")
        }
        
    }

    func updateBodyTextViewText(force: Bool = false){
        guard existingEmail == nil || force else { return }
        let name = nameTextField.text ?? "<Your Club Name Here>"
        let location = locationTextField.text ?? "<Club Meeting Spot>"
        let date = dateTextField.text ?? "<Club Meeting Time Here>"
        let nameText = name.isEmpty ? "<Your Club Name Here>" : name
        let locationText = location.isEmpty ? "<Club Meeting Spot>" : location
        let dateText = date.isEmpty ? "<Club Meeting Time Here>" : date.replacingOccurrences(of: "–", with: "at")
        bodyTextView.text = "Hi Everyone!\n\n\(nameText) is going to meet in the \(locationText) this \(dateText). We hope to see you there!\n\nBest,\nYour CoHeads"
    }
    func updateMeetingTimeText(sender: UIDatePicker){
        dateTextField.text = sender.date.getReadableString()
        selectedDate = sender.date
        updateBodyTextViewText()
        
    }
    
    func finishBodyTextView(){
        bodyTextView.resignFirstResponder()
    }
    func finishDatePicker(){
        dateTextField.resignFirstResponder()
        locationTextField.becomeFirstResponder()
    }
    
    func showAlert(title: String, message: String, action: (() -> Void)? = nil){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            action?()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Setup
    
    func checkExistingEmail(){
        guard let existingEmail = existingEmail?.info else { return }
        let name = existingEmail["name"] as? String
        title = "Edit"
        
        let existingDate = Date.getDate(fromServerString: (existingEmail["date"] as? String) ?? "")
        dateTextField.text = (existingDate ?? Date()).getReadableString()
    
        if let repeatInterval = existingEmail["repeatInterval"] as? String {
            var index = 1
            switch repeatInterval {
            case "Monthly" : index = 2
            case "Daily" : index = 0
            default: break
            }
            repeatDropdown.selectRowAtIndex(index)
        }
        
        nameTextField.text = name
        locationTextField.text = existingEmail["location"] as? String
        recipientTextField.text = (existingEmail["recipients"] as? [String])?.joined(separator: ", ")
        selectedDate = Date.getDate(fromServerString: (existingEmail["date"] as? String) ?? "")
        bodyTextView.text = existingEmail["body"] as? String
        if bodyTextView.text == nil { updateBodyTextViewText(force: true) }
    }
    
    @IBAction func showRepeatDropdown() {
        _ = repeatDropdown.show()
    }
    
    func setupDropDown() {
        repeatDropdown.anchorView = repeatButton
        repeatDropdown.direction = .bottom
        repeatDropdown.dismissMode = .automatic
        repeatDropdown.dataSource = RemindInterval.getAll()
        repeatDropdown.selectRowAtIndex(0)
        // Top of drop down will be below the anchorView
        repeatDropdown.topOffset = CGPoint(x: 0, y:(repeatDropdown.anchorView?.plainView.bounds.height)!)
        repeatDropdown.selectionAction = {(index: Int, item: String) in
            self.repeatButton.setTitle(item, for: .normal)
        }
        
        let appearance = DropDown.appearance()
        appearance.cellHeight = 60
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 0.2)
        //		appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 10
        appearance.shadowColor = UIColor(white: 0.6, alpha: 1)
        appearance.shadowOpacity = 0.9
        appearance.shadowRadius = 25
        appearance.animationduration = 0.25
        appearance.textColor = .black
        //		appearance.textFont = UIFont(name: "Georgia", size: 14)
    }
    
    //MARK: - Date Functions
    



}

extension EmailViewController : UITextFieldDelegate{
    

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag < 5 {
            view.viewWithTag(textField.tag + 1)?.becomeFirstResponder()
        }else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        updateBodyTextViewText()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBodyTextViewText()
    }
}

extension EmailViewController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
        bodyTextViewBottomConstraint.constant = keyboardHeight
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
        bodyTextViewBottomConstraint.constant = 8
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}
