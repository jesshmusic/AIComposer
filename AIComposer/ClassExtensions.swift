//
//  ClassExtensions.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/22/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

extension Int {
    
    /**
     Generates a random Int in specified range
     
     - range: `Range`
     - Returns: `Int`
     */
    static func random(range: Range<Int>) -> Int {
        var offset = 0
        if range.startIndex < 0 {
            offset = abs(range.startIndex)
        }
        let min = UInt32(range.startIndex + offset)
        let max = UInt32(range.endIndex + offset)
        return Int(min + arc4random_uniform(max - min)) - offset
    }
}

extension Double {
    
    
    /**
     Generates a random Double between 0 and 1
     
     - Returns: `Double`
     */
    static func random() -> Double {
        return Double(arc4random()) / Double(UINT32_MAX)
    }
}
