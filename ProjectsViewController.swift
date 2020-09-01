
  
//
//  ProjectsViewController.swift
//
//
//  Created by MongoDB on 2020-05-04.
// project == assets
// tasks == issues
//
import Foundation
import UIKit
import RealmSwift
import AVFoundation

class ProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVCaptureMetadataOutputObjectsDelegate  {
    let realm: Realm
    let assets: Results<Asset>
    let tableView = UITableView()
    var notificationToken: NotificationToken?
  
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        guard let user = app.currentUser() else {
            fatalError("Must be logged in to access this view")
        }
        
        // Open a realm with the partition key set to the user.
        // TODO: When support for user data is available, use the user data's list of
        // available projects.
        realm = try! Realm(configuration: user.configuration(partitionValue: user.identity!))
        
        // Access all objects in the realm, sorted by _id so that the ordering is defined.
        assets = realm.objects(Asset.self).sorted(byKeyPath: "_id")

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        // Observe the projects for changes.
        notificationToken = assets.observe { [weak self] (changes) in
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
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
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
        super.viewDidLoad()
        
        // Configure the view.
        title = "Projects"
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.frame = self.view.frame
        
        // On the top left is a log out button.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(logOutButtonDidClick))

        // On the top right is a button to add a Project.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonDidClick))

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.selectionStyle = .none
        let asset = assets[indexPath.row]
        cell.textLabel?.text = asset.assetId
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // User selected a project in the table. Go to the Project details page.
        let project = assets[indexPath.row]
        
        guard let user = app.currentUser() else {
            fatalError("Logged out?")
        }
        
        let projectRealm = try! Realm(configuration: user.configuration(partitionValue: "\(project._id)"))
//        TODO
       // navigationController!.pushViewController(TasksViewController(project: project, projectRealm: projectRealm), animated: true);
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        // The user can swipe to delete Projects.
        let asset = assets[indexPath.row]
        // All modifications must happen in a write block.
        try! realm.write {
            // Delete the project.
            realm.delete(asset)
        }
    }
    
    @objc func logOutButtonDidClick() {
        let alertController = UIAlertController(title: "Log Out", message: "", preferredStyle: .alert);
        alertController.addAction(UIAlertAction(title: "Yes, Log Out", style: .destructive, handler: {
            alert -> Void in
                print("Logging out...");
                app.logOut(completion: {(error) in
                    DispatchQueue.main.sync {
                        print("Logged out!");
                        self.navigationController?.setViewControllers([WelcomeViewController()], animated: true)
                    }
                })
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func addButtonDidClick() {
       
        let alertController = UIAlertController(title: "Add Project", message: "", preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: {
            alert -> Void in
                let textField = alertController.textFields![0] as UITextField
                let partition = app.currentUser()!.identity!
                let project = Asset(partition: partition, assetId: textField.text ?? "New Asset Id")

                // All writes must happen in a write block.
                try! self.realm.write {
                    self.realm.add(project)
                }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addTextField(configurationHandler: {(textField : UITextField!) -> Void in
            textField.placeholder = "New Project Name"
        })
        self.present(alertController, animated: true, completion: nil)
    }
   
        
        
        // Mark - Scanner delegate methods
       
}

