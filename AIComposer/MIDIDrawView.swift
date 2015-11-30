//
//  MIDIDrawView.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/7/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class MIDIDrawView: NSView {
    
    let noteHeight = 4.0
    let noteRadius:CGFloat = 0.5
    let beatWidth = 80.0
    
    var notePaths: [NSBezierPath]!

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        //// Color Declarations
        let bgColor = NSColor.blackColor()
        let noteColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 1.0, alpha: 1.0)
        let noteOutlineColor = NSColor(calibratedRed: 0.8, green: 0.8, blue: 1.0, alpha: 1.0)
        let gridColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.65)
        
        //// Rectangle Drawing
        let rectanglePath = NSBezierPath(rect: NSMakeRect(0, 0, dirtyRect.maxX, dirtyRect.maxY))
        bgColor.setFill()
        rectanglePath.fill()
        gridColor.setStroke()
        let numVertGridLines = 5
        let gridPath = NSBezierPath()
        var xPoint:Double = 15.0
        
        //  Vertical Grid
        
        gridPath.moveToPoint(NSPoint(x: xPoint, y: 0))
        for _ in 0..<numVertGridLines {
            gridPath.lineToPoint(NSPoint(x: xPoint, y: Double(dirtyRect.maxY)))
            xPoint = xPoint + beatWidth
            gridPath.moveToPoint(NSPoint(x: xPoint, y: 0))
        }
        
        //  Horizontal Grid
        
        // Thick lines
        var yPoint = 8.0
        gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        var cToE = true
        var yDistance = 4.0
        for _ in 0..<48 {
            gridPath.lineToPoint(NSPoint(x: beatWidth * 4.0 + 15.0, y: yPoint))
            if cToE {
                yDistance = 4.0
                cToE = false
            } else {
                yDistance = 5.0
                cToE = true
            }
            yPoint = yPoint + (yDistance * noteHeight)
            gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        }
        
        gridPath.lineWidth = 1.0
        gridPath.stroke()
        
        //  Thin lines
        yPoint = 8.0
        gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        for _ in 0..<127 {
            gridPath.lineToPoint(NSPoint(x: beatWidth * 4.0 + 15.0, y: yPoint))
            yPoint = yPoint + 4.0
            gridPath.moveToPoint(NSPoint(x: 15.0, y: yPoint))
        }
        
        gridPath.lineWidth = 0.5
        gridPath.stroke()
        noteColor.setFill()
        noteOutlineColor.setStroke()
        for notePath in notePaths {
            notePath.lineWidth = 0.8
            notePath.fill()
            notePath.stroke()
        }
    }
    
    func drawMIDINotes(notes: [MusicNote]) {
        self.notePaths = [NSBezierPath]()
        for note in notes {
            self.notePaths.append(self.createMIDINoteBezier(note))
        }
    }
    
    private func createMIDINoteBezier(note: MusicNote) -> NSBezierPath {
        let notePath = NSBezierPath(
            roundedRect: NSRect(
                x: Double(note.timeStamp) * beatWidth + 15.0,
                y: (Double(note.midiNoteMess.note) * noteHeight) - (40.0 * noteHeight),
                width: Double(note.midiNoteMess.duration) * beatWidth - 0.5,
                height: noteHeight),
            xRadius: noteRadius,
            yRadius: noteRadius)
        return notePath
    }
    
}
