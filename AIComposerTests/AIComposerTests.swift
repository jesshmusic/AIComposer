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
                noteMessage: MIDINoteMessage(channel: 1, note: 64, velocity: 64, releaseVelocity: 0, duration: 0.5),
                barBeatTime: CABarBeatTime(bar: 1, beat: 2, subbeat: 0, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(1.0))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 65, velocity: 64, releaseVelocity: 0, duration: 0.5),
                barBeatTime: CABarBeatTime(bar: 1, beat: 2, subbeat: 3, subbeatDivisor: 0, reserved: 0),
                timeStamp: MusicTimeStamp(1.5))
        )
        testMusicNotes.append(
            MusicNote(
                noteMessage: MIDINoteMessage(channel: 1, note: 66, velocity: 120, releaseVelocity: 0, duration: 1.0),
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
        XCTAssertLessThan(abs(testChords1[0].weight - chords1[0].weight), 0.00001)
        XCTAssertEqual(testChords1[1].chordName, chords1[1].chordName, "Possible chord names are not equal")
        XCTAssertLessThan(abs(testChords1[1].weight - chords1[1].weight), 0.00001)
        XCTAssertEqual(testChords1[2].chordName, chords1[2].chordName, "Possible chord names are not equal")
        XCTAssertLessThan(abs(testChords1[2].weight - chords1[2].weight), 0.00001)
        
        let testSnippet2 = self.testDataSet.musicSnippets[7]
        var testNotes2 = [Int]()
        var testTransNotes2 = [Int]()
        var testTimeStamps2 = [Double]()
        var testChords2 = testSnippet2.possibleChords
        let notes2 = [72, 71, 69, 67, 66, 69, 67, 71]
        let transNotes2 = [0, 11, 9, 7, 6, 9, 7, 11]
        let timeStamps2 = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75]
        let chords2 = [(chordName:"D7", weight: Float(0.181818)), (chordName:"F#dim", weight: Float(0.363636))]
        
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
        XCTAssertLessThan(abs(testChords2[0].weight - chords2[0].weight), 0.00001)
        XCTAssertEqual(testChords2[1].chordName, chords2[1].chordName, "Possible chord names are not equal")
        XCTAssertLessThan(abs(testChords2[1].weight - chords2[1].weight), 0.00001)
    }
    
    func testMusicSnippetEndCalc() {
        let snippet1 = self.testDataSet.musicSnippets[0]
        XCTAssertEqual(snippet1.endTime, 2.0)
        let snippet2 = self.testDataSet.musicSnippets[1]
        XCTAssertEqual(snippet2.endTime, 2.0)
        let snippet3 = self.testDataSet.musicSnippets[12]
        XCTAssertEqual(snippet3.endTime, 2.5)
        let snippet4 = self.testDataSet.musicSnippets[19]
        XCTAssertEqual(snippet4.endTime, 2.25)
    }
    
    
    //  Check note transpositions. Original note numbers: 60(C), 64(E), 65(F), 66(F#), 67(G)
    func testChromaticTransposeUp() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.chromaticTranspose(3)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(63))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(67))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(68))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(69))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(70))
        }
    }
    
    func testChromaticTransposeDown() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.chromaticTranspose(-3)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(57))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(61))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(62))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(63))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(64))
        }
    }
    
    func testDiatonicTransposeUp() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.diatonicTranspose(3, octaves: 0)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            //  Should be: F, A, B, C, C...
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(65))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(69))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(71))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(72))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(72))
        }
    }
    
    func testDiatonicTransposeDown() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.diatonicTranspose(-3, octaves: 0)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            //  Should be: G, B, C, C#, D
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(55))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(59))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(60))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(61))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(62))
        }
    }
    
    func testDiatonicTransposeUpPlusOctave() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.diatonicTranspose(3, octaves: 1)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(77))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(81))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(83))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(84))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(84))
        }
    }
    
    func testDiatonicTransposeUpPlus() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        transposedNotes.diatonicTranspose(0, octaves: 1)
        XCTAssertEqual(transposedNotes.count, 5)
        if transposedNotes.count == 5 {
            XCTAssertEqual(transposedNotes.musicNoteEvents[0].midiNoteMess.note, UInt8(72))
            XCTAssertEqual(transposedNotes.musicNoteEvents[1].midiNoteMess.note, UInt8(76))
            XCTAssertEqual(transposedNotes.musicNoteEvents[2].midiNoteMess.note, UInt8(77))
            XCTAssertEqual(transposedNotes.musicNoteEvents[3].midiNoteMess.note, UInt8(78))
            XCTAssertEqual(transposedNotes.musicNoteEvents[4].midiNoteMess.note, UInt8(79))
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
        let inversionNotes = composerController.getRetrograde(self.testMusicNotes)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, self.testMusicNotes[4].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, self.testMusicNotes[3].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, self.testMusicNotes[1].midiNoteMess.note)
            
            XCTAssertEqual(inversionNotes[0].timeStamp, self.testMusicNotes[4].timeStamp)
            XCTAssertEqual(inversionNotes[1].timeStamp, self.testMusicNotes[3].timeStamp)
            XCTAssertEqual(inversionNotes[2].timeStamp, self.testMusicNotes[2].timeStamp)
            XCTAssertEqual(inversionNotes[3].timeStamp, self.testMusicNotes[1].timeStamp)
            XCTAssertEqual(inversionNotes[4].timeStamp, self.testMusicNotes[0].timeStamp)
        }
    }
    
    func testMelodicRetrograde() {
        let retrogradeNotes = composerController.getRhythmicRetrograde(self.testMusicNotes)
        XCTAssertEqual(retrogradeNotes.count, 5)
        if retrogradeNotes.count == 5 {
            XCTAssertEqual(retrogradeNotes[0].midiNoteMess.note, self.testMusicNotes[4].midiNoteMess.note)
            XCTAssertEqual(retrogradeNotes[1].midiNoteMess.note, self.testMusicNotes[3].midiNoteMess.note)
            XCTAssertEqual(retrogradeNotes[2].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
            XCTAssertEqual(retrogradeNotes[3].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
            XCTAssertEqual(retrogradeNotes[4].midiNoteMess.note, self.testMusicNotes[1].midiNoteMess.note)
            
            XCTAssertEqual(retrogradeNotes[0].timeStamp, self.testMusicNotes[0].timeStamp)
            XCTAssertEqual(retrogradeNotes[1].timeStamp, self.testMusicNotes[1].timeStamp)
            XCTAssertEqual(retrogradeNotes[2].timeStamp, self.testMusicNotes[2].timeStamp)
            XCTAssertEqual(retrogradeNotes[3].timeStamp, self.testMusicNotes[3].timeStamp)
            XCTAssertEqual(retrogradeNotes[4].timeStamp, self.testMusicNotes[4].timeStamp)
        }
    }
    
    func testRhythmicRetrograde() {
        let inversionNotes = composerController.getRhythmicRetrograde(self.testMusicNotes)
        XCTAssertEqual(inversionNotes.count, 5)
        if inversionNotes.count == 5 {
            XCTAssertEqual(inversionNotes[0].midiNoteMess.note, self.testMusicNotes[0].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[1].midiNoteMess.note, self.testMusicNotes[1].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[2].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[3].midiNoteMess.note, self.testMusicNotes[3].midiNoteMess.note)
            XCTAssertEqual(inversionNotes[4].midiNoteMess.note, self.testMusicNotes[4].midiNoteMess.note)
            
            XCTAssertEqual(inversionNotes[0].timeStamp, self.testMusicNotes[4].timeStamp)
            XCTAssertEqual(inversionNotes[1].timeStamp, self.testMusicNotes[3].timeStamp)
            XCTAssertEqual(inversionNotes[2].timeStamp, self.testMusicNotes[2].timeStamp)
            XCTAssertEqual(inversionNotes[3].timeStamp, self.testMusicNotes[1].timeStamp)
            XCTAssertEqual(inversionNotes[4].timeStamp, self.testMusicNotes[0].timeStamp)
        }
    }
    
    func testGetFragment() {
        let transposedNotes = MusicSnippet(notes: self.testMusicNotes)
        let frag1 = transposedNotes.getFragment(1, endIndex: 3)
        XCTAssertEqual(frag1.musicNoteEvents[0].midiNoteMess.note, self.testMusicNotes[1].midiNoteMess.note)
        XCTAssertEqual(frag1.musicNoteEvents[1].midiNoteMess.note, self.testMusicNotes[2].midiNoteMess.note)
        XCTAssertEqual(frag1.musicNoteEvents[2].midiNoteMess.note, self.testMusicNotes[3].midiNoteMess.note)
        XCTAssertEqual(frag1.musicNoteEvents[0].timeStamp, MusicTimeStamp(0.0))
        XCTAssertEqual(frag1.musicNoteEvents[1].timeStamp, MusicTimeStamp(0.5))
        XCTAssertEqual(frag1.musicNoteEvents[2].timeStamp, MusicTimeStamp(1.0))
        XCTAssertEqual(frag1.musicNoteEvents[0].barBeatTime.beat, 1)
        XCTAssertEqual(frag1.musicNoteEvents[0].barBeatTime.subbeat, 0)
        
        let testSnippet1 = self.testDataSet.musicSnippets[2]
        let frag2 = testSnippet1.getFragment(3, endIndex: 6)
        XCTAssertEqual(frag2.musicNoteEvents[0].midiNoteMess.note, testSnippet1.musicNoteEvents[3].midiNoteMess.note)
        XCTAssertEqual(frag2.musicNoteEvents[1].midiNoteMess.note, testSnippet1.musicNoteEvents[4].midiNoteMess.note)
        XCTAssertEqual(frag2.musicNoteEvents[2].midiNoteMess.note, testSnippet1.musicNoteEvents[5].midiNoteMess.note)
        XCTAssertEqual(frag2.musicNoteEvents[3].midiNoteMess.note, testSnippet1.musicNoteEvents[6].midiNoteMess.note)
        XCTAssertEqual(frag2.musicNoteEvents[0].timeStamp, MusicTimeStamp(0.75))
        XCTAssertEqual(frag2.musicNoteEvents[1].timeStamp, MusicTimeStamp(1.0))
        XCTAssertEqual(frag2.musicNoteEvents[2].timeStamp, MusicTimeStamp(1.25))
        XCTAssertEqual(frag2.musicNoteEvents[3].timeStamp, MusicTimeStamp(1.5))
        XCTAssertEqual(frag2.musicNoteEvents[0].barBeatTime.beat, 1)
        XCTAssertEqual(frag2.musicNoteEvents[0].barBeatTime.subbeat, 360)
    }
    
    func testMergeNotePassages() {
        //  TODO: Figure out a test for this.
        let snippet1 = self.testDataSet.musicSnippets[0]
        let snippet2 = self.testDataSet.musicSnippets[5]
        var newNotes = [MusicNote]()
        var averageFromSnippet1: Double = 0.0
        var firstSnippetHits: Int = 0
        var totalNotesChecked: Int = 0
        for _ in 0..<100 {
            newNotes = composerController.mergeNotePassages(snippet1.musicNoteEvents, firstWeight: 0.75, secondPassage: snippet2.musicNoteEvents)
            for note in newNotes {
                totalNotesChecked++
                if snippet1.musicNoteEvents.contains(note) {
                    firstSnippetHits++
                }
            }
        }
        averageFromSnippet1 = Double(firstSnippetHits) / Double(totalNotesChecked)
        XCTAssertGreaterThan(averageFromSnippet1, 0.7)
        XCTAssertLessThan(averageFromSnippet1, 0.8)
    }
    
    func testCrescendo() {
        var dynamics:[UInt8] = [40, 50, 60, 70, 80]
        var crescPassage = composerController.createDynamicLine(self.testMusicNotes, startIndex: 0, endIndex: self.testMusicNotes.count - 1, startVelocity: 40, endVelocity: 80)
        XCTAssertEqual(crescPassage[0].midiNoteMess.velocity, dynamics[0])
        XCTAssertEqual(crescPassage[1].midiNoteMess.velocity, dynamics[1])
        XCTAssertEqual(crescPassage[2].midiNoteMess.velocity, dynamics[2])
        XCTAssertEqual(crescPassage[3].midiNoteMess.velocity, dynamics[3])
        XCTAssertEqual(crescPassage[4].midiNoteMess.velocity, dynamics[4])
        
        dynamics = [100, 80, 60, 40, 20]
        crescPassage = composerController.createDynamicLine(self.testMusicNotes, startIndex: 0, endIndex: self.testMusicNotes.count - 1, startVelocity: 100, endVelocity: 20)
        XCTAssertEqual(crescPassage[0].midiNoteMess.velocity, dynamics[0])
        XCTAssertEqual(crescPassage[1].midiNoteMess.velocity, dynamics[1])
        XCTAssertEqual(crescPassage[2].midiNoteMess.velocity, dynamics[2])
        XCTAssertEqual(crescPassage[3].midiNoteMess.velocity, dynamics[3])
        XCTAssertEqual(crescPassage[4].midiNoteMess.velocity, dynamics[4])
    }
    
    func testApplyArticulation() {
        let staccPassage = composerController.applyArticulation(self.testMusicNotes, startIndex: 2, endIndex: 3, articulation: Articulation.Staccato)
        
        XCTAssertEqual(staccPassage[2].midiNoteMess.duration, Float32(0.25))
        XCTAssertEqual(staccPassage[3].midiNoteMess.duration, Float32(0.5))
        
        let accentPassage = composerController.applyArticulation(self.testMusicNotes, startIndex: 2, endIndex: 3, articulation: Articulation.Accent)
        print(accentPassage)
        XCTAssertGreaterThan(accentPassage[2].midiNoteMess.velocity, self.testMusicNotes[2].midiNoteMess.velocity)
        XCTAssertGreaterThan(accentPassage[3].midiNoteMess.velocity, self.testMusicNotes[3].midiNoteMess.velocity)
        XCTAssertLessThan(accentPassage[2].midiNoteMess.velocity, 128)
        XCTAssertLessThan(accentPassage[3].midiNoteMess.velocity, 128)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
}
