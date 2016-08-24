//
//  ViewController.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/23/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import Firebase

typealias Email = (id: String, info: EmailInfo)
typealias EmailInfo = [String : AnyObject]

class MailSwipeViewController: UIViewController {
    


    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    var ref : FIRDatabaseReference!
    var needsUpdate = true
    
    var emails = [Email]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = FIRAuth.auth()?.currentUser else {
            fatalError("Could not find current user")
        }
        
        self.tableView.isHidden = self.emails.isEmpty

        ref = FIRDatabase.database().reference().child("users").child(user.uid)
        
        guard ref != nil else {
            tableView.isHidden = true
            return
        }
        
        addFirebaseObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: false)
        }
    }
    
    func addFirebaseObservers(){
        ref.observe(.childChanged, with: {(dataSnapshot) -> Void in
            for (i, email) in self.emails.enumerated() {
                if email.id == dataSnapshot.key {
                    let info = dataSnapshot.value as! [String : AnyObject]
                    let newEmail = (id: email.id, info: info)
                    self.emails.remove(at: i)
                    self.emails.insert(newEmail, at: i)
                    self.tableView.reloadData()
                    return
                }
            }
        })
        ref.observe(.childAdded, with: {(dataSnapshot) -> Void in
            print("Child Added: \(dataSnapshot.value!)")
            print("Key name: \(dataSnapshot.key)")
            
            guard let data = dataSnapshot.value as? [String : AnyObject] else {
                print("Getting Data Snapshot Failed")
                self.tableView.isHidden = true
                return
            }
            guard (data["name"] as? String) != nil else {
                print("Key to Name Translation Failed")
                self.tableView.isHidden = true
                return
            }
            self.emails.append((dataSnapshot.key, data))
            self.tableView.insertRows(at: [IndexPath(row: self.emails.count - 1, section: 0)], with: .fade)
            self.tableView.isHidden = self.emails.isEmpty
        })
        
        ref.observe(.childRemoved, with: {(dataSnapshot) -> Void in
            print("Child Removed: \(dataSnapshot.value)")
            
            let emailIds = self.emails.map({ (email: Email) -> String in
                return email.id
            })
            
            if let index = emailIds.index(of: dataSnapshot.key){
                self.emails.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
            
            self.tableView.isHidden = self.emails.isEmpty
        })

    }
    
    @IBAction func addEmail(_ sender: UIBarButtonItem) {
        let name = "Random Test Name \(Int(arc4random_uniform(1000)))"
        print("***\(name.removeSpaces())***")
        //ref.child(name.removeSpaces()).setValue(["name" : name])
    }
    
    //MARK: - Navigation
    
    private struct Storyboard {
        static let EditEmailSegue = "Edit Email Segue"
        static let CellIdentifier = "MainPageCell"
    }
    
    @IBAction func newEmailCancelled(segue: UIStoryboardSegue){
        //New Email Cancelled
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        var destination = segue.destination
        if let destinationNav = destination  as? UINavigationController {
            destination = destinationNav.visibleViewController!
        }
        switch identifier {
        case Storyboard.EditEmailSegue:
            guard let emailVC = destination as? EmailViewController, let index = tableView.indexPathForSelectedRow?.row else { return }
            emailVC.existingEmail = emails[index]
        default: break
        }
    }
    
}

extension MailSwipeViewController: UITableViewDelegate {

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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        
        cell.textLabel?.text = emails[indexPath.row].info["name"] as? String
        
        return cell
    }
    
}

