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
    case once = "Once"
    
    static func getAll() -> [String]{
        return ["Weekly", "Monthly", "Once"]
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
            dateTextField.inputAccessoryView = getToolbar(forText: "Next", forSelector: #selector(finishDatePicker))
            dateTextField.inputView = getDatePicker()
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
            bodyTextView.inputAccessoryView = getToolbar(forText: "Done", forSelector: #selector(finishBodyTextView))
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
        

        navigationController?.navigationBar.barTintColor = UIColor.init(colorLiteralRed: 5/255, green: 170/255, blue: 25/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.barStyle = .black

        
        updateBodyTextViewText()
        setupDropDown()
        checkExistingEmail()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(notification: Notification){
        keyboardHeight = CGFloat((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 8)
        keyboardAnimationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) ?? 0.1

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
            NotificationManager.scheduleEmailNotifications(forEmail: email, withName: email.info["name"]! as! String, withDate: self.selectedDate!)
            self.presentingViewController?.dismiss(animated: true, completion: nil)

        })
    }
    
    
    func getEmail() -> Email? {
        let name = nameTextField.text?.trim() ?? ""
        let location = locationTextField.text?.trim() ?? ""
        let repeatInterval = repeatButton.titleLabel?.text ?? ""
        let body = bodyTextView.text.trim() 
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
        
        let recipients = recipientText.extractEmails().map() { $0.trim() }
        guard recipients.count > 0 else { showUnfinishedAlert(); return nil }

//        guard recipients.count > 0 else {
//            showAlert(title: "Invalid Email Address", message: "You must enter at least one valid email address.")
//            return nil
//        }
//        
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
        var sheetsExists = false
        var driveExists = false
        if UIApplication.shared.canOpenURL(googleSheetsUrl) {
            sheetsExists = true
        }
        if UIApplication.shared.canOpenURL(googleDriveUrl) {
            driveExists = true
        }
        
        let alertController = UIAlertController(title: "Import Email Addresses", message: "You can copy in email addresses from all sorts of different places. Just go to an excel sheet or a previous email, copy the list of addresses, and paste them in the text box. If they don't paste, try pasting them somewhere else first (as different formats act strangely).", preferredStyle: .alert)
        if sheetsExists {
            alertController.addAction(UIAlertAction(title: "Open Google Sheets", style: .default, handler: { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(googleSheetsUrl, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(googleSheetsUrl)
                    // Fallback on earlier versions
                }
            }))
        }
        if driveExists {
            alertController.addAction(UIAlertAction(title: "Open Google Drive", style: .default, handler: { (_) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(googleDriveUrl, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(googleDriveUrl)
                    // Fallback on earlier versions
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
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
    
    //MARK: - Private Helper Functions
    
    private func setupDropDown() {
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
    
    private func getDatePicker() -> UIDatePicker {
        let lazyDatePicker = UIDatePicker()
        lazyDatePicker.datePickerMode = .dateAndTime
        lazyDatePicker.date = Date.getDate(fromServerString: (self.existingEmail?.info["date"] as? String) ?? "") ?? Date()
        lazyDatePicker.addTarget(self, action: #selector(updateMeetingTimeText(sender:)), for: .valueChanged)
        return lazyDatePicker
    }
    
    private func getToolbar(forText text: String, forSelector selector: Selector) -> UIToolbar{
        let doneToolbar = UIToolbar()
        doneToolbar.barStyle = .default
        doneToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: text, style: .done, target: self, action: selector)]
        doneToolbar.sizeToFit()
        return doneToolbar
    }
    
    



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
        
        var dif = (UIScreen.main.bounds.height - keyboardHeight) - textView.frame.origin.y
        dif = dif < 150 ? dif - 150 : 0

        bodyTextViewBottomConstraint.constant = keyboardHeight + dif
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.frame.origin.y = dif
            self.view.layoutIfNeeded()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.view.layoutIfNeeded()
        bodyTextViewBottomConstraint.constant = 8
        UIView.animate(withDuration: keyboardAnimationDuration) {
            self.view.frame.origin.y = 0
            self.view.layoutIfNeeded()
        }
    }
}
