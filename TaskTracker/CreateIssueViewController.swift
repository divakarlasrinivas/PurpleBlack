//
//  CreateIssueViewController.swift
//  TaskTracker
// 
//  Created by localadmin on 24/07/20.
//  Copyright © 2020 Santaneel Pyne. All rights reserved.
//

import Foundation
import Eureka
import RealmSwift
import AVFoundation

class CreateIssueViewController: FormViewController {
    let partitionValue: String
    let realm: Realm
    let assets: Results<Asset>
    let scannedAssetCode: String
    
    
    required init(_assetRealm: Realm, _code: String) {
        // Ensure the realm was opened with sync.
        guard let syncConfiguration = _assetRealm.configuration.syncConfiguration else {
            fatalError("Sync configuration not found! Realm not opened with sync?");
        }
        
        let queryStr: String =  "assetId == '"+_code+"'";
        realm = _assetRealm
        scannedAssetCode = _code
        assets = realm.objects(Asset.self).filter(queryStr)
        
        // Partition value must be of string type.
        partitionValue = syncConfiguration.partitionValue.stringValue!
        
      //  issues = issues.filter(queryStr);
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let selectedAsset = self.assets.first else {return}
        let assetId     = selectedAsset.assetId
        let description = selectedAsset.desc
        let location    = selectedAsset.location
        
        form +++ Section("Asset - "+assetId)
            <<< TextRow(){ row in
                row.title = "Description"
                //row.placeholder = "Enter text here"
                row.value = description
                row.disabled = true
                
            }
            <<< TextRow(){ row in
                row.title = "Location"
                //row.placeholder = "Enter text here"
                row.value = location
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
                                self.submitDataToRealm()
                            })
    }
    func submitDataToRealm(){
        print(form.values())
        
        // Create a new Issue with the text that the user entered.
        let issue = Issue(partition: self.partitionValue)
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
            // Add the Issue to the Realm. That's it!
            self.realm.add(issue)
        }
        
        self.navigationController!.pushViewController(TasksViewController( assetRealm: self.realm), animated: true);
        
    }
}
