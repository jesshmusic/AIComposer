//
//  AIComposerTests.swift
//  AIComposerTests
//
//  Created by Jess Hendricks on 10/30/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import XCTest
import CoreMIDI
@testable import AIComposer

class AIComposerTests: XCTestCase {
    
    var testDataSet: MusicDataSet!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.testDataSet = MusicDataSet()
        let filePath = NSBundle.mainBundle().URLForResource("Bach-Melody-WithCC20", withExtension: "mid")
        let filePathString = filePath?.path
        self.testDataSet.addNewMIDIFile(filePathString!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFileImport() {
        XCTAssertEqual(self.testDataSet.musicSnippets.count, 35, "Oops")
    }
    
    func testMusicSnippets() {
        
        let testSnippet1 = self.testDataSet.musicSnippets[0]
        var testNotes1 = [Int]()
        var testTransNotes1 = [Int]()
        var testTimeStamps1 = [Double]()
        var testChords1 = testSnippet1.possibleChords
        let notes1 = [60, 62, 64, 65, 62, 64, 60]
        let transNotes1 = [0, 2, 4, 5, 2, 4, 0]
        let timeStamps1 = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
        let chords1 = [(chordName:"F", weight: Float(0.3)), (chordName:"C", weight: Float(0.4)), (chordName:"Dm", weight: Float(0.3))]
        
        for nextNote in testSnippet1.musicNoteEvents {
            testNotes1.append(Int(nextNote.midiNoteMess.note))
            testTimeStamps1.append(nextNote.timeStamp)
        }
        for nextTransNote in testSnippet1.transposedNoteEvents {
            testTransNotes1.append(Int(nextTransNote.midiNoteMess.note))
        }
        
        XCTAssertEqual(testNotes1, notes1, "Note numbers are not equal")
        XCTAssertEqual(testTransNotes1, transNotes1, "Transposed Note numbers are not equal")
        XCTAssertEqual(testTimeStamps1, timeStamps1, "Time stamps are not equal")
        XCTAssertEqual(testChords1[0].chordName, chords1[0].chordName, "Possible chord names are not equal")
        XCTAssertEqual(testChords1[0].weight, chords1[0].weight, "Possible chord weights are not equal")
        XCTAssertEqual(testChords1[1].chordName, chords1[1].chordName, "Possible chord names are not equal")
        XCTAssertEqual(testChords1[1].weight, chords1[1].weight, "Possible chord weights are not equal")
        XCTAssertEqual(testChords1[2].chordName, chords1[2].chordName, "Possible chord names are not equal")
        XCTAssertEqual(testChords1[2].weight, chords1[2].weight, "Possible chord weights are not equal")
        
        let testSnippet2 = self.testDataSet.musicSnippets[7]
        var testNotes2 = [Int]()
        var testTransNotes2 = [Int]()
        var testTimeStamps2 = [Double]()
        var testChords2 = testSnippet2.possibleChords
        let notes2 = [72, 71, 69, 67, 66, 69, 67, 71]
        let transNotes2 = [0, 11, 9, 7, 6, 9, 7, 11]
        let timeStamps2 = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
        let chords2 = [(chordName:"F#dim", weight: Float(1.0))]
        
        for nextNote in testSnippet2.musicNoteEvents {
            testNotes2.append(Int(nextNote.midiNoteMess.note))
            testTimeStamps2.append(nextNote.timeStamp)
        }
        for nextTransNote in testSnippet2.transposedNoteEvents {
            testTransNotes2.append(Int(nextTransNote.midiNoteMess.note))
        }
        
        XCTAssertEqual(testNotes2, notes2, "Note numbers are not equal")
        XCTAssertEqual(testTransNotes2, transNotes2, "Transposed Note numbers are not equal")
        XCTAssertEqual(testTimeStamps2, timeStamps2, "Time stamps are not equal")
        XCTAssertEqual(testChords2[0].chordName, chords2[0].chordName, "Possible chord names are not equal")
        XCTAssertEqual(testChords2[0].weight, chords2[0].weight, "Possible chord weights are not equal")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
