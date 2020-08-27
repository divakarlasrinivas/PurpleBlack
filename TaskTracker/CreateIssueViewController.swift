//
//  CreateIssueViewController.swift
//  TaskTracker
//
//  Created by localadmin on 24/07/20.
//  Copyright © 2020 Srinivas Divakarla. All rights reserved.
//

import Foundation
import Eureka
import RealmSwift
import AVFoundation

class CreateIssueViewController: FormViewController {
    let submitButton = UIButton(type: .roundedRect)
    let assets: Asset?
    let partitionValue: String
    let realm: Realm
    let issues: Results<Issue>
    let scannedAssetCode: String
    
    
    required init(_assets: Asset?, _assetRealm: Realm, _code: String) {
        // Ensure the realm was opened with sync.
        guard let syncConfiguration = _assetRealm.configuration.syncConfiguration else {
            fatalError("Sync configuration not found! Realm not opened with sync?");
        }
        
        let queryStr: String =  "assetId == '"+_code+"'";
        print(queryStr);
        self.assets = _assets
        
        self.realm = _assetRealm
        self.scannedAssetCode = _code
        
        issues = realm.objects(Issue.self).sorted(byKeyPath: "_id").filter(queryStr)
       // print("issues that contain assetIDs: \(issues.filter(queryStr).count)");
       
       
        // Partition value must be of string type.
        partitionValue = syncConfiguration.partitionValue.stringValue!

        // Access all tasks in the realm, sorted by _id so that the ordering is defined.
        // Only tasks with the project ID as the partition key value will be in the realm.
        
       
      //  issues = issues.filter(queryStr);
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section("Asset - "+self.scannedAssetCode)
            <<< TextRow(){ row in
                row.title = "Description"
                //row.placeholder = "Enter text here"
                row.value = "Water Pump"
                row.disabled = true
                
            }
            <<< TextRow(){ row in
                row.title = "Location"
                //row.placeholder = "Enter text here"
                row.value = "SUB XYZ12 Tudor Road"
                row.disabled = true
                
            }
            
        +++ Section("Please enter issue details")
            <<< TextRow(){ row in
                row.title = "Description"
                row.placeholder = "Enter text here"
                
                row.tag = "description"
                
            }
            <<< TextRow(){ row in
                row.title = "Issue Id"
                row.placeholder = "Enter text here"
                
                row.tag = "issueId"
                
            }
            <<< TextRow(){ row in
                row.title = "Created By"
                row.placeholder = "Enter text here"
                
                row.tag = "createdBy"
                
            }
            <<< SegmentedRow<String>("Priority"){
                $0.options = ["High", "Medium", "Low"]
                $0.value = "Low"
                $0.tag = "priority"
            }
            <<< ButtonRow() { (row: ButtonRow) -> Void in
                            row.title = "Submit"
                            }  .onCellSelection({ (cell, row) in
                                self.submitDataToMongo()
                            })
    }
    func submitDataToMongo(){
        print(form.values())
        
        // Create a new Task with the text that the user entered.
                 let issue = Issue(partition: self.partitionValue, assetId: "1000")
        let createdByRow: TextRow? = form.rowBy(tag: "createdBy")
        let descriptionRow: TextRow? = form.rowBy(tag: "description")
        let priorityRow: SegmentedRow<String>? = form.rowBy(tag: "priority")
        let issueIdRow: TextRow? = form.rowBy(tag: "issueId")
        
        issue.issueId = issueIdRow?.value ?? ""
        issue.createdBy = createdByRow?.value ?? ""
        issue.desc = descriptionRow?.value ?? ""
        issue.priority = priorityRow?.value ?? "Low"
        issue.status = "Open"
        issue.assetId = self.scannedAssetCode
        
        try! self.realm.write {
            // Add the Task to the Realm. That's it!
            self.realm.add(issue)
        }
        
        self.navigationController!.pushViewController(TasksViewController(project: self.assets, assetRealm: self.realm), animated: true);
        
    }
}
