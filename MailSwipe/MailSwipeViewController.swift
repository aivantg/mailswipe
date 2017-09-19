//
//  ViewController.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/23/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import Firebase
import MessageUI
import UserNotifications

typealias Email = (id: String, info: EmailInfo)
typealias EmailInfo = [String : Any]

class MailSwipeViewController: UIViewController {
    


    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet weak var sendButton: UIBarButtonItem!
    var ref : FIRDatabaseReference!
    var needsUpdate = true
    var sendingEmail = false {
        didSet{
            print("Changed Sending Email to \(sendingEmail)")
            sendButton.title = sendingEmail ? "Cancel" : "Send"
        }
    }
    
    var emails = [Email]()
    
    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.isHidden = false
        tableView.contentInset = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)

        setupDatabaseConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sendingEmail = false
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MailSwipeViewController.setupDatabaseConnections) , name: Notification.Name(Constants.UserAuthenticatedNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sendingEmail = false
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupDatabaseConnections(){
        print("Setting up Database Connections")
        guard ref == nil else {
            print("Database Connection already set")
            return
        }
        guard let user = FIRAuth.auth()?.currentUser else {
            print("Could not find current user")
            tableView.isHidden = true
            return
        }
        
        self.tableView.isHidden = self.emails.isEmpty
        
        ref = FIRDatabase.database().reference().child("users").child(user.uid)
        
        guard ref != nil else {
            tableView.isHidden = true
            return
        }
        
        addFirebaseObservers()
        
        
    }
    
    func addFirebaseObservers(){
        
        //When info changes, find the email that changed, remove it, and insert the new one
        ref.observe(.childChanged, with: {(dataSnapshot) -> Void in
            for (i, email) in self.emails.enumerated() {
                if email.id == dataSnapshot.key {
                    let info = dataSnapshot.value as! [String : Any]
                    let newEmail = (id: email.id, info: info)
                    self.emails.remove(at: i)
                    self.emails.insert(newEmail, at: i)
                    self.tableView.reloadData()
                    return
                }
            }
        })
        
        //When email added, make sure the data exists and is valid (otherwise hide the table)
        ref.observe(.childAdded, with: {(dataSnapshot) -> Void in
            
            guard let data = dataSnapshot.value as? [String : AnyObject] else {
                self.tableView.isHidden = true
                return
            }
            guard (data["name"] as? String) != nil else {
                self.tableView.isHidden = true
                return
            }
            self.emails.append((dataSnapshot.key, data))
            self.tableView.insertRows(at: [IndexPath(row: self.emails.count - 1, section: 0)], with: .fade)
            self.tableView.isHidden = self.emails.isEmpty
        })
        
        //When email removed, get email id's, check against the data snapshot, and remove it as well as cancel scheduled notifications
        ref.observe(.childRemoved, with: {(dataSnapshot) -> Void in
            
            let emailIds = self.emails.map({ (email: Email) -> String in
                return email.id
            })
            
            if let index = emailIds.index(of: dataSnapshot.key){
                let email = self.emails[index]
                if let notificationIdentifier = UserDefaults.standard.object(forKey: email.id) as? String{
                    for notification in UIApplication.shared.scheduledLocalNotifications ?? [] {
                        guard let id = notification.userInfo?["id"] as? String else { continue }
                        if id == notificationIdentifier {
                            UIApplication.shared.cancelLocalNotification(notification)
                        }
                    }
                    UserDefaults.standard.set(nil, forKey: email.id)
                }
                self.emails.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
            
            self.tableView.isHidden = self.emails.isEmpty
        })

    }
    
    
    @IBAction func sendEmail(_ sender: AnyObject) {
        switch sendingEmail{
        case true: sendingEmail = false
        case false:
            sendingEmail = true
            showAlert(title: "Send Email", message: "Select an email to send.")

        }
    }
    
    func showAlert(title: String, message: String, action: (() -> Void)? = nil){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            action?()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func openEmailEditor(forEmailInfo emailInfo: EmailInfo){
        guard MFMailComposeViewController.canSendMail() else {
            showAlert(title: "Unable to Send", message: "Please configure your device to send emails before trying to send.")
            return
        }
        guard
            let subject = emailInfo["name"] as? String,
            let recipients = emailInfo["recipients"] as? [String],
            let body = emailInfo["body"] as? String else {
                showAlert(title: "Unable to Get Email", message: "Please try again or delete and re-add this email reminder.")
                return
        }
        
        let mailVC = MFMailComposeViewController()
        mailVC.navigationBar.tintColor = UIColor.white
        mailVC.mailComposeDelegate = self
        mailVC.setSubject(subject)
        mailVC.setToRecipients(recipients)
        mailVC.setMessageBody(body, isHTML: false)
        
        present(mailVC, animated: true, completion: nil)
        
    }

    
    //MARK: - Navigation
    
    struct Storyboard {
        static let EditEmailSegue = "Edit Email Segue"
        static let CellIdentifier = "MainPageCell"
    }
    
    @IBAction func newEmailCancelled(segue: UIStoryboardSegue){
        //New Email Cancelled
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        let destination = segue.destination.contentViewController
        switch identifier {
        case Storyboard.EditEmailSegue:
            guard let emailVC = destination as? EmailViewController, let index = tableView.indexPathForSelectedRow?.row else { return }
            print("Index: \(index)")
            emailVC.existingEmail = emails[index]
        default: break
        }
    }
    
}

extension MailSwipeViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        if let error = error {
            showAlert(title: "Error Sending Mail", message: error.localizedDescription)
        }
        
    }
}

extension MailSwipeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Did Select Row \(indexPath), sending Email: \(sendingEmail)")
        switch sendingEmail {
        case true:
            openEmailEditor(forEmailInfo: emails[indexPath.row].info)
            sendingEmail = false
            tableView.deselectRow(at: indexPath, animated: true)
        case false: performSegue(withIdentifier: Storyboard.EditEmailSegue, sender: nil)
        }
        
    }
    
    @nonobjc func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            ref.child(emails[indexPath.row].id).removeValue()
        default:
            break;
        }
    }
}

extension MailSwipeViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        let emailInfo = emails[indexPath.row].info
        cell.textLabel?.text = emailInfo["name"] as? String
        if let serverString = emailInfo["date"] as? String {
            cell.detailTextLabel?.text = getNextMeetingText(fromServerString: serverString, forRemindInterval: RemindInterval(rawValue: (emailInfo["repeatInterval"] as? String) ?? ""))
        }
        return cell
    }
    
    func getNextMeetingText(fromServerString serverString: String, forRemindInterval interval: RemindInterval?) -> String? {
        var date = Date.getDate(fromServerString: serverString)
        guard date != nil else {
            return nil
        }
        
        let calendar = Calendar.current
        while(date != nil && date! < Date()) {
            var dateComponent = DateComponents()
            switch interval ?? .weekly {
                case .monthly:
                    dateComponent.month = 1
                case .weekly:
                    dateComponent.weekOfYear = 1
                case .once:
                    return nil
            }
            date = calendar.date(byAdding: dateComponent, to: date!)
        }
        
        let curDateComponents = calendar.dateComponents([.day, .month], from: Date())
        let secDateComponents = calendar.dateComponents([.day, .month], from: date!)
        var days = 0
        let secDays = secDateComponents.day!
        let curDays = curDateComponents.day!
        if secDays < curDays {
            let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
            days = (daysInMonth - curDays) + secDays
        }else {
            days = secDays - curDays
        }
        var returnString = "Next Meeting: "
        if days == 0 {
            returnString += "Tomorrow!"
        }else if days < 0 {
            returnString += "Today!"
        }else {
            returnString += "In \(days + 1) Days"
        }
        return returnString
        
    }
    
}
