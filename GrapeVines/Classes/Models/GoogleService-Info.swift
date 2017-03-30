//
//  GoogleService-Info.swift
//  GrapeVines
//
//  Created by imac on 3/14/17.
//  Copyright © 2017 Daniel Team. All rights reserved.
//

import Firebase

class FIRDataObject: NSObject {
    let snapshot: FIRDataSnapshot
    var key: String { return snapshot.key }
    var ref: FIRDatabaseReference { return snapshot.ref }
    
    required init(snapshot: FIRDataSnapshot) {
        self.snapshot = snapshot
        
        super.init()
        
        for child in snapshot.children.allObjects as? [FIRDataSnapshot] ?? [] {
            if responds(to: Selector(child.key)) {
                setValue(child.value, forKey: child.key)
            }
        }
    }
}
