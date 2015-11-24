//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

/// The `Singleton` instance
private let ComposerControllerInstance = ComposerController()


class ComposerController: NSObject {
    
    
    let presetList: [UInt8] = [1, 2, 5, 6, 7, 12, 25, 46, 47,
        81, 82, 99, 100]
    
    
    let permWeights = [20, 40, 50, 60, 100]
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  Creates a MIDI file that tests all permutations with a single MusicSnippet
    func createPermutationTestSequence(fileName fileName: String, musicSnippets: [MusicSnippet], mainSnippetIndex: Int, mainSnippetWeight: Double) -> [MusicSnippet] {
        var newSnippets = [MusicSnippet]()
        var musicSnippet: MusicSnippet!
        if musicSnippets[mainSnippetIndex].getHighestWeightChord().containsString("m") {
            musicSnippet = MusicSnippet(notes: musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("Cm")
        } else {
            musicSnippet = MusicSnippet(notes: musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("C")
        }
        if musicSnippets.count > 1 {
            for _ in 0..<3 {
                musicSnippet = self.createNewMotive(musicSnippets, snippet: musicSnippets[mainSnippetIndex], weight: mainSnippetWeight)
            }
        } else {
            musicSnippet = MusicSnippet(notes: musicSnippets[0].musicNoteEvents)
        }
        if musicSnippet.count != 0 {
            //  Initialize the MusicSequence
            var newSequence = MusicSequence()
            NewMusicSequence(&newSequence)
            MusicSequenceSetSequenceType(newSequence, MusicSequenceType.Beats)
            
            //  Create a tempo track with a random tempo
            var tempoTrack = MusicTrack()
            
            MusicSequenceGetTempoTrack(newSequence, &tempoTrack)
            let newTempo: Float64 = Float64(Int.random(40...140))
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, newTempo)
            
            //  Create a musicTrack by filling measures with music transposed to that chord.
            var musicTrack = MusicTrack()
            MusicSequenceNewTrack(newSequence, &musicTrack)
            
            let randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
            var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0.0, &chanmess)
            chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0, &chanmess)
            chanmess = MIDIChannelMessage(status: 0xC0, data1: randomPreset, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0, &chanmess)
            
            let chordsSet = [["C", "Em", "F", "Dm", "G", "C"], ["C", "Eb", "F", "Gm", "G", "Am"], ["F", "C", "Dm", "Am", "G", "C"], ["C", "G", "Am", "Em", "F", "C", "Dm", "G", "C"]]
//            let chords = chordsSet[3]
            let chords = chordsSet[Int.random(0...3)]
            
            var timeOffset: MusicTimeStamp = musicSnippet.musicNoteEvents[0].timeStamp
            var currentTime: MusicTimeStamp = timeOffset
            
            for chord in chords {
                let addedEvent = self.generateNextSnippet(chord: chord, musicSnippets: musicSnippets, musicSnippet: musicSnippet, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
                timeOffset = addedEvent.timeStamp
                currentTime = self.setNextTimeStamp(currentTime)
                newSnippets.append(addedEvent.newSnippet)
            }

            //  Add a transposed version 2
            var silentNoteForSpace = MIDINoteMessage(channel: 0, note: 0, velocity: 0, releaseVelocity: 0, duration: 2.0)
            MusicTrackNewMIDINoteEvent(musicTrack, currentTime + 3.0, &silentNoteForSpace)
            
            let midiFilePlayer = MIDIFilePlayer.sharedInstance
            midiFilePlayer.createMIDIFile(fileName: fileName, sequence: newSequence)
        }
        return newSnippets
    }
    
    private func generateNextSnippet(chord
        chord: String,
        musicSnippets: [MusicSnippet],
        musicSnippet: MusicSnippet,
        timeOffset: MusicTimeStamp,
        currentTime: MusicTimeStamp,
        musicTrack: MusicTrack
        ) -> (timeStamp: MusicTimeStamp, newSnippet: MusicSnippet)
    {
        let newMergeSnippet = self.createNewMotive(musicSnippets, snippet: musicSnippet, weight: 0.6)
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet)
        snippet1.transposeToChord(chord)
        let addedEvent = self.addMusicSnippetToSequence(snippet1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
        return (addedEvent.timeStamp, addedEvent.newSnippet)
    }
    
    private func setNextTimeStamp(var currentTime: MusicTimeStamp) -> MusicTimeStamp {
        currentTime = currentTime + 4.0
        return currentTime
    }
    
    private func createNewMotive(musicSnippets: [MusicSnippet], snippet: MusicSnippet, weight: Double) -> MusicSnippet {
        var musicSnippet = MusicSnippet()
        for i in 0..<musicSnippets.count {
            if i != musicSnippets.indexOf(snippet) {
                if musicSnippets[i].getHighestWeightChord() == snippet.getHighestWeightChord() {
                    musicSnippet = snippet.mergeNotePassages(firstWeight: weight, secondSnippet: musicSnippets[i])
                    break
                }
            }
        }
        return musicSnippet
    }
    
    private func addMusicSnippetToSequence(musicSnippet: MusicSnippet, var timeOffset: MusicTimeStamp, currentTime: MusicTimeStamp, musicTrack: MusicTrack) -> (timeStamp: MusicTimeStamp, newSnippet: MusicSnippet) {
        for note in musicSnippet.musicNoteEvents {
            var midiNoteMessage = MIDINoteMessage()
            midiNoteMessage.channel = note.midiNoteMess.channel
            midiNoteMessage.duration = note.midiNoteMess.duration
            midiNoteMessage.note = note.midiNoteMess.note
            midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
            midiNoteMessage.velocity = note.midiNoteMess.velocity
            MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
        }
        musicSnippet.humanizeNotes()
        timeOffset = timeOffset + musicSnippet.endTime
        return (timeOffset, musicSnippet)
    }
    
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet) -> MusicSnippet {
        let newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
        var permuteNum = 0
        let rand = Int.random(0...100)
        while (rand > self.permWeights[permuteNum]) {
            permuteNum++
        }
        
        switch permuteNum {
        case 0:
            newSnippet.applyDiatonicInversion(pivotNoteNumber: musicSnippet.musicNoteEvents[0].midiNoteMess.note)
        case 1:
            newSnippet.applyMelodicRetrograde()
        case 2:
            newSnippet.applyRetrograde()
        case 3:
            newSnippet.applyRhythmicRetrograde()
        default:
            break
        }
        
        if Double.random() < 0.25 {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            newSnippet.applyDynamicLine(startIndex: start, endIndex: end, startVelocity: UInt8(Int.random(25..<127)), endVelocity: UInt8(Int.random(25..<127)))
        } else if Double.random() < 0.5 {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            let randomArticulationNum = Int.random(0...10)
            var artic: Articulation!
            switch randomArticulationNum {
            case 0, 1, 2:
                artic = Articulation.Accent
            case 3, 4:
                artic = Articulation.Marcato
            case 5, 6:
                artic = Articulation.Staccatissimo
            case 7, 8, 9:
                artic = Articulation.Staccato
            default:
                artic = Articulation.Tenuto
            }
            newSnippet.applyArticulation(startIndex: start, endIndex: end, articulation: artic)
        }
        
        return newSnippet
    }
    
    
}
