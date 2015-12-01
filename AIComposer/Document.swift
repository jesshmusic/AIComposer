//
//  Document.swift
//  AIComposer
//
//  Created by Jess Hendricks on 10/30/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var currentLoadedFile: String!
    var musicDataSet: MusicDataSet!
//    let composerController = ComposerController.sharedInstance
    let midiManager = MIDIManager.sharedInstance
    
    @IBOutlet weak var clearDataButton: NSButtonCell!
    @IBOutlet weak var deleteSnippetbutton: NSButton!
    @IBOutlet weak var playButton: NSButton!
    
    @IBOutlet weak var musicSnippetTableView: NSTableView!
    @IBOutlet weak var chordProgressionTableView: NSTableView!
    @IBOutlet weak var compositionsTableView: NSTableView!
    
    @IBOutlet weak var deleteCompositionButton: NSButton!
    @IBOutlet var consoleTextView: NSTextView!
    @IBOutlet weak var composeButton: NSButton!
    
    @IBOutlet weak var numberOfGenesTextField: NSTextField!
    @IBOutlet weak var maxGenerationsTextField: NSTextField!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        if self.musicDataSet != nil {
            //            self.textOutputView.string = self.musicDataSet!.getDataString()
            self.musicSnippetTableView.reloadData()
            if self.musicDataSet.compositions.count > 0 {
                self.updateMusicFitnessScores()
                self.playButton.enabled = true
                self.playButton.title = "PLAY"
            } else {
                self.playButton.enabled = false
            }
        } else {
            self.musicDataSet = MusicDataSet()
            self.clearDataButton.enabled = false
            self.playButton.enabled = false
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedPlaying", name: "Finished playing MIDI", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "compositionDataDisplay:", name: "ComposerControllerData", object: nil)
    }
    
    func finishedPlaying() {
        self.playButton.title = "PLAY"
    }
    
    func compositionDataDisplay(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            let userInfo = notification.userInfo as! [String: String]
            self.consoleTextView.string = self.consoleTextView.string! + "\(userInfo["Data String"]!)\n"
            self.consoleTextView.scrollRangeToVisible(NSRange(location: (self.consoleTextView.string!.characters.count), length: 0))
        }
    }
    
    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }
    
    override func dataOfType(typeName: String) throws -> NSData {
        if let archivableMusicDataSet = self.musicDataSet {
            return NSKeyedArchiver.archivedDataWithRootObject(archivableMusicDataSet)
        }
        throw NSError(domain: "AIComposerDocumentDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not archive Music Data File", comment: "Archive error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("No Music Data was available for the document", comment: "Archive failure reason")
            ])
    }
    
    override func readFromData(data: NSData, ofType typeName: String) throws {
        
        self.musicDataSet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MusicDataSet
        
        if let _ = self.musicDataSet {
            if self.musicDataSet.compositions.count > 0 {
                self.updateMusicFitnessScores()
            }
            return
        }
        
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
            ])
    }
    
    private func updateMusicFitnessScores() {
        let compCtrl = ComposerController(musicDataSet: self.musicDataSet)
        for compIndex in 0..<self.musicDataSet.compositions.count {
            self.musicDataSet.compositions[compIndex] = compCtrl.recalculateFitnessForComposition(self.musicDataSet.compositions[compIndex])
        }
    }
    
    @IBAction func loadMIDIFile(sender: AnyObject) {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        let path = myFileDialog.URL?.path
        
        
        // Make sure that a path was chosen
        if (path != nil) {
            //  Add the contents of the file to the MusicDataSet
            if sender.tag() == 0 {
                self.musicDataSet!.parseMusicSnippetsFromMIDIFile(path!)
                self.clearDataButton.enabled = true
                self.musicSnippetTableView.reloadData()
            } else if sender.tag() == 1 {
                self.musicDataSet!.parseChordProgressionsFromMIDIFile(path!)
                self.chordProgressionTableView.reloadData()
            }
        }
    }
    
    @IBAction func clearAllMidiData(sender: AnyObject) {
        let clearAlert = NSAlert()
        clearAlert.messageText = "Warning!"
        clearAlert.informativeText = "This will delete all imported MIDI data from this document"
        clearAlert.alertStyle = NSAlertStyle.CriticalAlertStyle
        clearAlert.addButtonWithTitle("Cancel")
        clearAlert.addButtonWithTitle("Confirm")
        
        let choice = clearAlert.runModal()
        
        switch choice{
        case NSAlertSecondButtonReturn:
            if self.musicDataSet?.musicSnippets.count != 0 {
                self.musicDataSet!.clearAllData()
                self.musicSnippetTableView.reloadData()
                self.clearDataButton.enabled = false
            }
        default:
            break
        }
    }
    
    @IBAction func deleteSnippet(sender: AnyObject) {
        let selectedRow = self.musicSnippetTableView.selectedRow
        if selectedRow > -1 {
            self.musicDataSet.musicSnippets.removeAtIndex(selectedRow)
            self.musicSnippetTableView.reloadData()
        }
    }
    
    /*
    *   returns the chord progression at the selected row.
    */
    func selectedChordProgression() -> MusicChordProgression? {
        let selectedRow = self.chordProgressionTableView.selectedRow
        if selectedRow >= 0 && selectedRow < self.musicDataSet.chordProgressions.count {
            return self.musicDataSet.chordProgressions[selectedRow]
        }
        return nil
    }
    
    @IBAction func deleteProgression(sender: AnyObject) {
        if let _ = self.selectedChordProgression() {
            self.musicDataSet.removeChordProgression(self.chordProgressionTableView.selectedRow)
            self.chordProgressionTableView.removeRowsAtIndexes(NSIndexSet(index: self.chordProgressionTableView.selectedRow), withAnimation: NSTableViewAnimationOptions.SlideRight)
        }
    }
    @IBAction func createComposition(sender: AnyObject) {
        self.consoleTextView.string = "Generating compositions...\n-------------------------------------\n"
        
        self.composeButton.enabled = false
        self.composeButton.title = "Composing..."
        
        self.createNewComposition(background: {
            if self.numberOfGenesTextField.integerValue > 0 && self.maxGenerationsTextField.integerValue > 0 {
                let composerController = ComposerController(musicDataSet: self.musicDataSet, numberOfGenes: self.numberOfGenesTextField.integerValue, maxGenerations: self.maxGenerationsTextField.integerValue)
                self.musicDataSet = composerController.createComposition()
            } else {
                let composerController = ComposerController(musicDataSet: self.musicDataSet)
                self.musicDataSet = composerController.createComposition()
            }
            },
            completion: {
                self.composeButton.enabled = true
                self.composeButton.title = "Compose"
                self.musicSnippetTableView.reloadData()
                self.compositionsTableView.reloadData()
                self.playButton.enabled = true
        })
        
    }
    
    func createNewComposition(delay: Double = 0.0, background:(() -> Void)? = nil, completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if(background != nil){ background!(); }
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue()) {
                if(completion != nil){ completion!(); }
            }
        }
    }
    
    private func temp() {
        
    }
    
    @IBAction func exportCompositionMIDIFile(sender: AnyObject) {
        let selectedSequenceRow = self.compositionsTableView.selectedRow
        if selectedSequenceRow > -1 {
            let myFileDialog: NSSavePanel = NSSavePanel()
            myFileDialog.runModal()
            
            let path = myFileDialog.URL?.path
            if (path != nil) {
                self.midiManager.createMIDIFile(fileName: path!, sequence: self.musicDataSet.compositions[selectedSequenceRow].musicSequence)
            }
        }
    }
    
    @IBAction func deleteComposition(sender: AnyObject) {
        let selectedSequenceRow = self.compositionsTableView.selectedRow
        if selectedSequenceRow > -1 {
            let clearAlert = NSAlert()
            clearAlert.messageText = "Warning!"
            clearAlert.informativeText = "This will permanently delete the selected composition."
            clearAlert.alertStyle = NSAlertStyle.CriticalAlertStyle
            clearAlert.addButtonWithTitle("Cancel")
            clearAlert.addButtonWithTitle("Confirm")
            
            let choice = clearAlert.runModal()
            
            switch choice{
            case NSAlertSecondButtonReturn:
                self.musicDataSet.compositions.removeAtIndex(selectedSequenceRow)
                self.compositionsTableView.reloadData()
            default:
                break
            }
        }
    }
    
    @IBAction func playButton(sender: AnyObject) {
        let selectedSequenceRow = self.compositionsTableView.selectedRow
        if selectedSequenceRow > -1 {
            self.midiManager.createMIDIPlayer(self.musicDataSet.compositions[selectedSequenceRow].musicSequence)
            self.midiManager.play()
            if self.midiManager.isPlaying {
                self.playButton.title = "STOP"
            } else {
                self.playButton.title = "PLAY"
            }
        }
    }
}


extension Document: NSTableViewDataSource {
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if self.musicDataSet != nil {
            if tableView == self.chordProgressionTableView {
                return self.musicDataSet.chordProgressions.count
            }
            
            if tableView == self.musicSnippetTableView {
                return self.musicDataSet.musicSnippets.count
            }
            
            if tableView == self.compositionsTableView {
                return self.musicDataSet.compositions.count
            }
        }
        
        return 1
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        if self.musicDataSet != nil {
            if tableView == self.chordProgressionTableView {
                let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! ChordProgressionCellView
                let nextProgression = self.musicDataSet.chordProgressions[row]
                cellView.chordInfoTextField!.stringValue = "Progression (\(nextProgression.chords.count) chords):"
                cellView.chordProgressionTextField!.stringValue = nextProgression.description
                return cellView
            } else if tableView == self.musicSnippetTableView {
                if !self.musicDataSet.musicSnippets.isEmpty {
                    let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! MusicSnippetCellView
                    let nextSnippet = self.musicDataSet.musicSnippets[row]
                    cellView.musicSnippetInfo.stringValue = nextSnippet.infoString
                    cellView.musicSnippetData.stringValue = nextSnippet.dataString
                    cellView.musicSnippetMIDIDrawView.drawMIDINotes(nextSnippet.musicNoteEvents)
                    return cellView
                }
                return nil
            } else if tableView == self.compositionsTableView {
                if !self.musicDataSet.compositions.isEmpty {
                    let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! CompositionFileCellView
                    let nextCompositionFile = self.musicDataSet.compositions[row]
                    cellView.fileInfoTextField.stringValue = nextCompositionFile.dataString
                    cellView.fileTextField.stringValue = nextCompositionFile.name
                    cellView.fileChordProgression.stringValue = nextCompositionFile.chordProgressionString
                    return cellView
                }
            }
        }
        return nil
    }
}

extension Document: NSTableViewDelegate {
    
}

