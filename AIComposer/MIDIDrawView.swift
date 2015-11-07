//
//  MIDIDrawView.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/7/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class MIDIDrawView: NSView {
    
    var notePaths = [NSBezierPath]()

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        //// Color Declarations
        let color = NSColor(calibratedRed: 0.166, green: 0.217, blue: 0.17, alpha: 1)
        
        //// Rectangle Drawing
        let rectanglePath = NSBezierPath(rect: NSMakeRect(0, 0, dirtyRect.maxX, dirtyRect.maxY))
        color.setFill()
        rectanglePath.fill()
    }
    
    func drawMIDINotes(notes: [MusicNote]) {
        
    }
    
//    private func createMIDINoteBezier(note: MusicNote) -> NSBezierPath {
//        
//    }
    
}
