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
    
    @IBOutlet var textOutputView: NSTextView!
    @IBOutlet weak var clearDataButton: NSButtonCell!
    @IBOutlet weak var exportMIDIbutton: NSButton!
    
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        if self.musicDataSet != nil {
            self.textOutputView.string = self.musicDataSet!.getDataString()
        } else {
            self.musicDataSet = MusicDataSet()
            self.clearDataButton.enabled = false
            self.exportMIDIbutton.enabled = false
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
            self.musicDataSet!.addNewMIDIFile(path!)
            self.clearDataButton.enabled = true
            self.exportMIDIbutton.enabled = true
            self.textOutputView.string = self.musicDataSet!.getDataString()
        }
        //        print(self.musicDataSet.description)
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
                self.textOutputView.string = "All MIDI data deleted."
                self.clearDataButton.enabled = false
                self.exportMIDIbutton.enabled = false
            }
        default:
            break
        }
    }
    
    
    @IBAction func exportMIDIFile(sender: AnyObject) {
        let myFileDialog: NSSavePanel = NSSavePanel()
        myFileDialog.runModal()
        
        let path = myFileDialog.URL?.path
        if (path != nil) {
            self.musicDataSet.createMIDIFileFromDataSet(path!)
        }
    }
}

