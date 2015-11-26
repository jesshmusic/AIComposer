//
//  CompositionFileCellView.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/24/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class CompositionFileCellView: NSTableCellView {
    
    @IBOutlet weak var fileInfoTextField: NSTextField!
    @IBOutlet weak var fileTextField: NSTextField!

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
}
