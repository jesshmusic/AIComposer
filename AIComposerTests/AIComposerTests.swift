//
//  AIComposerTests.swift
//  AIComposerTests
//
//  Created by Jess Hendricks on 10/30/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import XCTest
import CoreMIDI
import AudioToolbox
@testable import AIComposer

class AIComposerTests: XCTestCase {
    
    var testDataSet: MusicDataSet!
    var testMusicNotes = [MusicNote]()
    
    let composerController = ComposerController.sharedInstance
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.testDataSet = MusicDataSet()
        let filePath = NSBundle.mainBundle().URLForResource("Bach-Melody-WithCC20", withExtension: "mid")
        let filePathString = filePath?.path
        self.testDataSet.parseMusicSnippetsFromMIDIFile(filePathString!)
        
        
        
        // Create a music snippet to test composition permutations (transposing, retrograde, etc)... C-quarter, E-eighth, F-eighth, F#-quarter, G-quarter
        
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 60, velocity: 64, releaseVelocity: 0, duration: 1.0),
                barBeatTime: CABarBeatTime(bar: 1, beat: 1, subbeat: 0, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(0.0))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 64, velocity: 64, releaseVelocity: 0, duration: 1.0),
                barBeatTime: CABarBeatTime(bar: 1, beat: 2, subbeat: 0, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(1.0))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 65, velocity: 64, releaseVelocity: 0, duration: 1.0),
                barBeatTime: CABarBeatTime(bar: 1, beat: 2, subbeat: 3, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(1.5))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 66, velocity: 64, releaseVelocity: 0, duration: 1.0),
                barBeatTime: CABarBeatTime(bar: 1, beat: 3, subbeat: 0, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(2.0))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 67, velocity: 64, releaseVelocity: 0, duration: 1.0),
                barBeatTime: CABarBeatTime(bar: 1, beat: 4, subbeat: 0, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(3.0))
        )
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
        let chords1 = [(chordName:"F", weight: Float(0.461538)), (chordName:"C", weight: Float(0.307692)), (chordName:"Dm", weight: Float(0.230769))]
        
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
        //        XCTAssertEqual(testChords1[0].weight, chords1[0].weight, "Possible chord weights are not equal")
        XCTAssertEqual(testChords1[1].chordName, chords1[1].chordName, "Possible chord names are not equal")
        //        XCTAssertEqual(testChords1[1].weight, chords1[1].weight, "Possible chord weights are not equal")
        XCTAssertEqual(testChords1[2].chordName, chords1[2].chordName, "Possible chord names are not equal")
        //        XCTAssertEqual(testChords1[2].weight, chords1[2].weight, "Possible chord weights are not equal")
        
        let testSnippet2 = self.testDataSet.musicSnippets[7]
        var testNotes2 = [Int]()
        var testTransNotes2 = [Int]()
        var testTimeStamps2 = [Double]()
        //        var testChords2 = testSnippet2.possibleChords
        let notes2 = [72, 71, 69, 67, 66, 69, 67, 71]
        let transNotes2 = [0, 11, 9, 7, 6, 9, 7, 11]
        let timeStamps2 = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
        //        let chords2 = [(chordName:"F#dim", weight: Float(1.0))]
        
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
        //        XCTAssertEqual(testChords2[0].chordName, chords2[0].chordName, "Possible chord names are not equal")
        //        XCTAssertEqual(testChords2[0].weight, chords2[0].weight, "Possible chord weights are not equal")
    }
    
    
    //  Check note transpositions. Original note numbers: 60(C), 64(E), 65(F), 66(F#), 67(G)
    func testChromaticTransposeUp() {
        let transposedNotes = composerController.chromaticTranspose(self.testMusicNotes, halfSteps: 3)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(63))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(67))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(68))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(69))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(70))
        }
    }
    
    func testChromaticTransposeDown() {
        let transposedNotes = composerController.chromaticTranspose(self.testMusicNotes, halfSteps: -3)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(57))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(61))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(62))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(63))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(64))
        }
    }
    
    func testDiatonicTransposeUp() {
        let transposedNotes = composerController.diatonicTranspose(self.testMusicNotes, steps: 3, octaves: 0)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            //  Should be: F, A, B, C, C...
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(65))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(69))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(71))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(72))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(72))
        }
    }
    
    func testDiatonicTransposeDown() {
        let transposedNotes = composerController.diatonicTranspose(self.testMusicNotes, steps: -3, octaves: 0)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            //  Should be: G, B, C, C#, D
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(55))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(59))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(60))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(61))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(62))
        }
    }
    
    func testDiatonicTransposeUpPlusOctave() {
        let transposedNotes = composerController.diatonicTranspose(self.testMusicNotes, steps: 3, octaves: 1)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(77))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(81))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(83))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(84))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(84))
        }
    }
    
    func testDiatonicTransposeUpPlus() {
        let transposedNotes = composerController.diatonicTranspose(self.testMusicNotes, steps: 0, octaves: 1)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes[0].midiNoteMess.note, UInt8(72))
            XCTAssertEqual(transposedNotes[1].midiNoteMess.note, UInt8(76))
            XCTAssertEqual(transposedNotes[2].midiNoteMess.note, UInt8(77))
            XCTAssertEqual(transposedNotes[3].midiNoteMess.note, UInt8(78))
            XCTAssertEqual(transposedNotes[4].midiNoteMess.note, UInt8(79))
        }
    }
    
    func testChromaticInversion() {
        var inversionNotes = composerController.getChromaticInversion(self.testMusicNotes, pivotNoteNumber: 60)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, UInt8(60))
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, UInt8(56))
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, UInt8(55))
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, UInt8(54))
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, UInt8(53))
        }
        inversionNotes = composerController.getChromaticInversion(self.testMusicNotes, pivotNoteNumber: 55)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, UInt8(50))
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, UInt8(46))
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, UInt8(45))
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, UInt8(44))
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, UInt8(43))
        }
    }
    
    func testDiatonicInversion() {
        var inversionNotes = composerController.getDiatonicInversion(self.testMusicNotes, pivotNoteNumber: 60)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, UInt8(60))
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, UInt8(57))
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, UInt8(55))
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, UInt8(54))
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, UInt8(53))
        }
        inversionNotes = composerController.getDiatonicInversion(self.testMusicNotes, pivotNoteNumber: 53)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, UInt8(47))
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, UInt8(42))
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, UInt8(40))
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, UInt8(40))
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, UInt8(39))
        }
    }
    
    func testRetrograde() {
        let inversionNotes = composerController.getChromaticInversion(self.testMusicNotes, pivotNoteNumber: 60)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, UInt8(60))
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, UInt8(57))
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, UInt8(55))
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, UInt8(54))
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, UInt8(53))
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
