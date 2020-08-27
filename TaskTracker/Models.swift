//
//  Models.swift
//  TaskTracker
//
//  Created by Srinivas Divakarla on 23/07/20.
//  Copyright © 2020 Srinivas Divakarla. All rights reserved.
//

import Foundation
import RealmSwift

typealias ProjectId = String
typealias AssetId = String
class Asset: Object {
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var _partition = ""
    @objc dynamic var assetId = ""
    //@objc dynamic  var description = ""
    @objc dynamic  var type = ""
    @objc dynamic  var location = ""
    @objc dynamic var desc = ""
    
    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience init(partition: String, assetId: String) {
        self.init()
        self._partition = partition
        self.assetId = assetId
      //  self.description = description
       // self.name = name
    }
}

class User: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: String = ""
    @objc dynamic var image: String? = nil
    @objc dynamic var name: String = ""
    @objc dynamic var user_id: String = ""
    override static func primaryKey() -> String? {
        return "_id"
    }
}

enum IssueStatus: String {
  case Open
  case InProgress
  case Closed
}
enum Priority: String {
    case High
    case Medium
    case Low
}

class Issue: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var _partition: AssetId = ""
  
 
    @objc dynamic var status = ""
    
    @objc dynamic var issueId = ""
   // @objc dynamic var description = ""
    @objc dynamic var assetId: AssetId = ""
    @objc dynamic var createdBy = ""
    @objc dynamic var priority = Priority.Low.rawValue
    @objc dynamic var desc  = ""
      
       
    var priorityEnum: Priority{
        get{
            return Priority(rawValue: priority) ?? .Low
        }
        set {
            priority = newValue.rawValue
        }
    }
    
    
    var statusEnum: IssueStatus {
        get {
            return IssueStatus(rawValue: status) ?? .Open
        }
        set {
            status = newValue.rawValue
        }
    }

    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience init(partition: String, assetId: String) {
        self.init()
        self._partition = partition
        //self.assetId = assetId
    }
}
