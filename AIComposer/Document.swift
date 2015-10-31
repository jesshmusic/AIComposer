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
    var musicDataSet: MusicDataSet?
    
    @IBOutlet var textOutputView: NSTextView!
    
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
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: "AIComposerDocumentDomain", code: -1, userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Could not archive Music Data File", comment: "Archive error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString("No Music Data was available for the document", comment: "Archive failure reason")
            ])
    }
    
    override func readFromData(data: NSData, ofType typeName: String) throws {
        
        self.musicDataSet = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MusicDataSet
        
        if let _ = self.musicDataSet {
//            print(musicDataSet.getDataString())
            return
            //            self.textOutputView.string = musicDataSet.getDataString()
        }
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
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
        }
        self.textOutputView.string = self.musicDataSet!.getDataString()
        //        print(self.musicDataSet.description)
    }
    
}

