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
    let composerController = ComposerController.sharedInstance
    let midiFilePlayer = MIDIFilePlayer.sharedInstance
    
    @IBOutlet weak var clearDataButton: NSButtonCell!
    @IBOutlet weak var exportMIDIbutton: NSButton!
    @IBOutlet weak var playButton: NSButton!
    
    @IBOutlet weak var musicSnippetTableView: NSTableView!
    @IBOutlet weak var chordProgressionTableView: NSTableView!
    
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
        } else {
            self.musicDataSet = MusicDataSet()
            self.clearDataButton.enabled = false
            self.exportMIDIbutton.enabled = false
        }
        self.playButton.enabled = false
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
            return
        }
        
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
            ])
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
                self.exportMIDIbutton.enabled = true
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
        clearAlert.addButtonWithTitle("DELETE ALL")
        
        let choice = clearAlert.runModal()
        
        switch choice{
        case NSAlertSecondButtonReturn:
            if self.musicDataSet?.musicSnippets.count != 0 {
                self.musicDataSet!.clearAllData()
                self.musicSnippetTableView.reloadData()
                self.clearDataButton.enabled = false
                self.exportMIDIbutton.enabled = false
            }
        default:
            break
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
    
    
    @IBAction func exportMIDIFile(sender: AnyObject) {
        let myFileDialog: NSSavePanel = NSSavePanel()
        myFileDialog.runModal()
        
        let path = myFileDialog.URL?.path
        if (path != nil) {
            self.musicDataSet.createMIDIFileFromDataSet(path!)
        }
    }
    
    @IBAction func deleteProgression(sender: AnyObject) {
        if let _ = self.selectedChordProgression() {
            self.musicDataSet.chordProgressions.removeAtIndex(self.chordProgressionTableView.selectedRow)
            self.chordProgressionTableView.removeRowsAtIndexes(NSIndexSet(index: self.chordProgressionTableView.selectedRow), withAnimation: NSTableViewAnimationOptions.SlideRight)
        }
    }
    @IBAction func createTestFile(sender: AnyObject) {
        let myFileDialog: NSSavePanel = NSSavePanel()
        myFileDialog.beginWithCompletionHandler({ (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let path = myFileDialog.URL?.path
                if (path != nil) {
                    let selectedSnippetRow = self.musicSnippetTableView.selectedRow
                    let newSnippets = self.composerController.createPermutationTestSequence(fileName: path!, musicSnippet: self.musicDataSet.musicSnippets[selectedSnippetRow])
                    self.musicDataSet.musicSnippets.appendContentsOf(newSnippets)
                    self.musicSnippetTableView.reloadData()
                    self.playButton.enabled = true
                } else {
                    print("Canceled")
                }
            }
        })
        
    }
    
    @IBAction func loadTestMIDIFile(sender: AnyObject) {
        
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.beginWithCompletionHandler({ (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                // Get the path to the file chosen in the NSOpenPanel
                let path = myFileDialog.URL?.path
                
                
                // Make sure that a path was chosen
                if (path != nil) {
                    self.midiFilePlayer.loadMIDIFile(fileName: path!)
                    self.playButton.enabled = true
                }
                
            }
        })
    }
    
    @IBAction func playButton(sender: AnyObject) {
        self.midiFilePlayer.playCurrentFile()
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
            } else {
                if !self.musicDataSet.musicSnippets.isEmpty {
                    let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! MusicSnippetCellView
                    let nextSnippet = self.musicDataSet.musicSnippets[row]
                    cellView.musicSnippetInfo.stringValue = nextSnippet.infoString
                    cellView.musicSnippetData.stringValue = nextSnippet.dataString
                    cellView.musicSnippetMIDIDrawView.drawMIDINotes(nextSnippet.musicNoteEvents)
                    return cellView
                }
                return nil
                
            }
        }
        return nil
    }
}

extension Document: NSTableViewDelegate {
    
}

