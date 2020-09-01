//
//  TasksViewController.swift
//  Task Tracker
// 
//  Created by MongoDB on 2020-05-07.
//  Copyright © 2020 MongoDB, Inc. All rights reserved.
//
import UIKit
import RealmSwift
import AVFoundation

class TasksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ScannerDelegate,AVCaptureMetadataOutputObjectsDelegate {
    // Mark - AVFoundation delegate methods
        public func metadataOutput(_ output: AVCaptureMetadataOutput,
                                   didOutput metadataObjects: [AVMetadataObject],
                                   from connection: AVCaptureConnection) {
            guard let scanner = self.scanner else {
                return
            }
            scanner.metadataOutput(output,
                                   didOutput: metadataObjects,
                                   from: connection)
        }
    // Mark - Scanner delegate methods
    
        func cameraView() -> UIView
        {
            return self.view
        }
        
        func delegateViewController() -> UIViewController
        {
            return self
        }
        
        func scanCompleted(withCode code: String)
        {
            currentBarcode = code
            // pass the scanned barcode to the CreateIssueViewController and Query MongoDB Realm
            let queryStr: String =  "assetId == '"+code+"'";
            print(queryStr);
            print("issues that contain assetIDs: \(assets.filter(queryStr).count)");
            if(assets.filter(queryStr).count > 0 ){
                scanner?.requestCaptureSessionStopRunning()
                self.navigationController!.pushViewController(CreateIssueViewController(_assetRealm: self.realm, _code: currentBarcode!), animated: true);
            }else{
                self.showToast(message: "No Asset found for the scanned code", seconds: 0.6)
            }

        }
    

    let partitionValue: String
    let realm: Realm
    let issues: Results<Issue>
    let assets: Results<Asset>
    let tableView = UITableView()
    var notificationToken: NotificationToken?
    private var scanner: Scanner?
    private var currentBarcode: String?

    required init(assetRealm: Realm) {
        // Ensure the realm was opened with sync.
        guard let syncConfiguration = assetRealm.configuration.syncConfiguration else {
            fatalError("Sync configuration not found! Realm not opened with sync?");
        }

    
        realm = assetRealm

        // Partition value must be of string type.
        partitionValue = syncConfiguration.partitionValue.stringValue!

        // Access all tasks in the realm, sorted by _id so that the ordering is defined.
        // Only tasks with the project ID as the partition key value will be in the realm.
        issues = realm.objects(Issue.self).sorted(byKeyPath: "_id")
        assets = realm.objects(Asset.self).sorted(byKeyPath: "_id")
        print(issues)
        print(assets)
        super.init(nibName: nil, bundle: nil)

        // Observe the tasks for changes.
        notificationToken = issues.observe { [weak self] (changes) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView.
                tableView.beginUpdates()
                // It's important to be sure to always update a table in this order:
                // deletions, insertions, then updates. Otherwise, you could be unintentionally
                // updating at the wrong index!
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }),
                    with: .automatic)
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                    with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                    with: .automatic)
                tableView.endUpdates()
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // Always invalidate any notification tokens when you are done with them.
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        // Configure the view.
        super.viewDidLoad()

        //if (project == nil) {
            // TUTORIAL ONLY:
            // If project was not set, we do not have the Projects page.
            // We must be using the default project for tutorial purposes.
            // That means instead of letting the left bar button go back to the
            // previous page, we will set it as the Log Out button.
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logOutButtonDidClick))
        //}

        title = "Issues"
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.frame = self.view.frame
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidClick))
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issues.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // This defines how the Tasks in the list look.
        // We want the task name on the left and some indication of its status on the right.
        let issue = issues[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.selectionStyle = .none
        cell.textLabel?.text = issue.issueId + " - " + issue.desc
        switch (issue.statusEnum) {
        case .Open:
            let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
            label.text = "Open"
            cell.accessoryView = label
        case .InProgress:
            let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
            label.text = "In Progress"
            cell.accessoryView = label
        case .Closed:
            let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
            label.text = "Closed"
            cell.accessoryView = label
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        // User can swipe to delete items.
        let issue = issues[indexPath.row]
        
        // All modifications to a realm must happen in a write block.
        try! realm.write {
            // Delete the Task.
            realm.delete(issue)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // User selected a task in the table. We will present a list of actions that the user can perform on this task.
        let issue = issues[indexPath.row]

        // Create the AlertController and add its actions.
        let actionSheet: UIAlertController = UIAlertController(title: issue.desc, message: "Select an action", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                print("Cancel")
            })

        // If the task is not in the Open state, we can set it to open. Otherwise, that action will not be available.
        // We do this for the other two states -- InProgress and Complete.
        if (issue.statusEnum != .Open) {
            actionSheet.addAction(UIAlertAction(title: "Open", style: .default) { _ in
                    // Any modifications to managed objects must occur in a write block.
                    // When we modify the Task's state, that change is automatically reflected in the realm.
                    try! self.realm.write {
                        issue.status = "Open"
                    }
                })
        }

        if (issue.statusEnum != .InProgress) {
            actionSheet.addAction(UIAlertAction(title: "Start Progress", style: .default) { _ in
                    try! self.realm.write {
                        issue.status = "InProgress"
                    }
                })
        }

        if (issue.statusEnum != .Closed) {
            actionSheet.addAction(UIAlertAction(title: "Closed", style: .default) { _ in
                    try! self.realm.write {
                        issue.status = "Closed"
                    }
                })
        }

        // Show the actions list.
        self.present(actionSheet, animated: true, completion: nil)
    }


    @objc func addButtonDidClick() {
        // User clicked the add button.
        print("add button clicked")
        // open camera
        self.scanner = Scanner(withDelegate: self)
        guard let scanner = self.scanner else {
            return
        }
                
                scanner.requestCaptureSessionStartRunning()
//        let alertController = UIAlertController(title: "Add Task", message: "", preferredStyle: .alert)
//
//        // When the user clicks the add button, present them with a dialog to enter the task name.
//        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: {
//            alert -> Void in
//            let textField = alertController.textFields![0] as UITextField
//
//            // Create a new Task with the text that the user entered.
//            let task = Task(partition: self.partitionValue, name: textField.text ?? "New Task")
//
//            // Any writes to the Realm must occur in a write block.
//            try! self.realm.write {
//                // Add the Task to the Realm. That's it!
//                self.realm.add(task)
//            }
//        }))
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        alertController.addTextField(configurationHandler: { (textField: UITextField!) -> Void in
//            textField.placeholder = "New Task Name"
//        })
//
//        // Show the dialog.
//        self.present(alertController, animated: true, completion: nil)
    }

    @objc func logOutButtonDidClick() {
        let alertController = UIAlertController(title: "Log Out", message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "Yes, Log Out", style: .destructive, handler: {
            alert -> Void in
            print("Logging out...");
            app.logOut(completion: { (error) in
                DispatchQueue.main.sync {
                    print("Logged out!");
                    self.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
                }
            })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
extension TasksViewController{

func showToast(message : String, seconds: Double){
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
 }
