//
//  ViewController.swift
//  MailSwipe
//
//  Created by Aivant Goyal on 8/23/16.
//  Copyright © 2016 aivantgoyal. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    typealias Email = (id: String, name: String)

    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    var ref : FIRDatabaseReference!
    
    var emails = [Email]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let user = FIRAuth.auth()?.currentUser else {
            fatalError("Could not find current user")
        }
        
        ref = FIRDatabase.database().reference().child("users").child(user.uid)
        
        guard ref != nil else {
            tableView.isHidden = true
            return
        }
        
        addFirebaseObservers()
    }
    
    func addFirebaseObservers(){
        ref.observe(.childAdded, with: {(dataSnapshot) -> Void in
            print("Child Added: \(dataSnapshot.value!)")
            print("Key name: \(dataSnapshot.key)")
            
            guard let data = dataSnapshot.value as? [String : String] else {
                print("Getting Data Snapshot Failed")
                self.tableView.isHidden = true
                return
            }
            guard let emailName = data["name"] else {
                print("Key to Name Translation Failed")
                self.tableView.isHidden = true
                return
            }
            self.emails.append((dataSnapshot.key, emailName))
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
        ref.child(name.removeSpaces()).setValue(["name" : name])
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected row #\(indexPath.row)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
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

extension ViewController: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.CellIdentifier, for: indexPath)
        
        cell.textLabel?.text = emails[indexPath.row].name
        
        return cell
    }
    
    private struct Storyboard {
        static let CellIdentifier = "MainPageCell"
    }
}

