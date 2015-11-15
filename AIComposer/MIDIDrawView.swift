//
//  MIDIDrawView.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/7/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class MIDIDrawView: NSView {
    
    var notePaths: [NSBezierPath]!

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        //// Color Declarations
        let bgColor = NSColor.blackColor()
        let noteColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 1.0, alpha: 1.0)
        let gridColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.65)
        
        //// Rectangle Drawing
        let rectanglePath = NSBezierPath(rect: NSMakeRect(0, 0, dirtyRect.maxX, dirtyRect.maxY))
        bgColor.setFill()
        rectanglePath.fill()
        gridColor.setStroke()
        let numVertGridLines = Int(dirtyRect.maxX / 60)
        let gridPath = NSBezierPath()
        var xPoint:Double = 15.0
        
        //  Vertical Grid
        
        gridPath.moveToPoint(NSPoint(x: xPoint, y: 0))
        for _ in 0..<numVertGridLines {
            gridPath.lineToPoint(NSPoint(x: xPoint, y: Double(dirtyRect.maxY)))
            xPoint = xPoint + 60
            gridPath.moveToPoint(NSPoint(x: xPoint, y: 0))
        }
        
        //  Horizontal Grid
        var yPoint = 8.0
        gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        var cToE = true
        var yDistance = 4.0
        for _ in 0..<48 {
            gridPath.lineToPoint(NSPoint(x: Double(dirtyRect.maxX), y: yPoint))
            if cToE {
                yDistance = 4.0
                cToE = false
            } else {
                yDistance = 5.0
                cToE = true
            }
            yPoint = yPoint + (yDistance * 2.0)
            gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        }
        
        gridPath.lineWidth = 0.5
        gridPath.stroke()
        noteColor.setFill()
        for notePath in notePaths {
            notePath.fill()
        }
    }
    
    func drawMIDINotes(notes: [MusicNote]) {
        self.notePaths = [NSBezierPath]()
        for note in notes {
            self.notePaths.append(self.createMIDINoteBezier(note))
        }
    }
    
    private func createMIDINoteBezier(note: MusicNote) -> NSBezierPath {
        let notePath = NSBezierPath(roundedRect: NSRect(x: Double(note.timeStamp) * 60.0 + 15.0, y: (Double(note.midiNoteMess.note) * 2.0) - 80.0, width: Double(note.midiNoteMess.duration) * 60.0, height: 2.0), xRadius: 1.0, yRadius: 1.0)
        return notePath
    }
    
}
