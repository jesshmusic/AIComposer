//
//  MusicSnippetCellView.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/7/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class MusicSnippetCellView: NSTableCellView {
    
    @IBOutlet weak var musicSnippetInfo: NSTextField!
    @IBOutlet weak var musicSnippetData: NSTextField!
    @IBOutlet weak var musicSnippetMIDIDrawView: MIDIDrawView!

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        // Drawing code here.
    }
    
}
