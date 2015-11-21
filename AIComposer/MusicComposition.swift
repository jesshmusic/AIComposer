//
//  MusicComposition.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/21/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

class MusicComposition: NSObject {
    
    //  Class variables
    let filePath: NSURL!
//    let name: String!
    
    init(filePath: NSURL) {
        self.filePath = filePath
    }
}
