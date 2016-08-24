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


class EmailViewController: UIViewController {
    
    var existingEmail : Email?
    
    var selectedDate : Date?

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
            datePicker.date = getDate(fromServerString: (existingEmail?.info["date"] as? String) ?? "") ?? Date()
            datePicker.addTarget(self, action: #selector(updateMeetingTimeText(sender:)), for: .valueChanged)
            
            let doneToolbar = UIToolbar()
            doneToolbar.barStyle = .default
            doneToolbar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(finishDatePicker))]
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
                UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(finishBodyTextView))]
            doneToolbar.sizeToFit()
            bodyTextView.inputAccessoryView = doneToolbar
        }
    }
    @IBOutlet weak var repeatButton: NiceButton!
    
    let repeatDropdown = DropDown()
    
    var keyboardFrame : CGRect?
    
    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.becomeFirstResponder()
        updateBodyTextViewText()
        setupDropDown()
        checkExistingEmail()
        // Do any additional setup after loading the view.
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
        self.presentingViewController?.dismiss(animated: true, completion: nil)
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
        
        let recipients = recipientText.components(separatedBy: ",").map() { $0.trim() }
        guard recipients.count > 0 else { showUnfinishedAlert(); return nil }
        
        return (id: name.removeSpaces(), info: ["name" : name, "location" : location, "repeatInterval" : repeatInterval, "body" : body, "recipients" : recipients, "date" : getServerString(fromDate: date)])
    }
    
        func showUnfinishedAlert(withTitle title: String? = nil, withMessage message: String? = nil){
        let alert = UIAlertController(title: title ?? "Fill Out Every Field", message: message ?? "Please fill out all the fields in order to continue.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    
    //MARK: - UI Actions

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
        dateTextField.text = getReadableString(fromDate: sender.date)
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
    
    //MARK: - Setup
    
    func checkExistingEmail(){
        guard let existingEmail = existingEmail?.info else { return }
        let name = existingEmail["name"] as? String
        title = "Edit \(name ?? "Email")"
        
        let existingDate = getDate(fromServerString: (existingEmail["date"] as? String) ?? "")
        dateTextField.text = getReadableString(fromDate: existingDate ?? Date())
    
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
        selectedDate = getDate(fromServerString: (existingEmail["date"] as? String) ?? "")
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
        repeatDropdown.dataSource = ["Daily", "Weekly", "Monthly"]
        repeatDropdown.selectRowAtIndex(1)
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
    
    //MARK: - Date Functiond
    
    func getDate(fromReadableString string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE – hh:mm a"
        return dateFormatter.date(from: string)
    }
    func getDate(fromServerString string: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE/hh:mma"
        return dateFormatter.date(from: string)
    }
    
    func getReadableString(fromDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE – hh:mm a"
        return dateFormatter.string(from: date)
    }
    
    func getServerString(fromDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE/hh:mma"
        return dateFormatter.string(from: date)
    }
    


}

extension EmailViewController : UITextFieldDelegate, UITextViewDelegate{
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
