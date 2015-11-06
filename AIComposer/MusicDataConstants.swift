//
//  MusicDataConstants.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/6/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

/// The `Singleton` instance
private let MusicDataConstantsInstance = MusicDataConstants()

class MusicDataConstants: NSObject {
    
    var harmonicProgressionGraphMAJOR: UnweightedGraph<String>!
    var harmonicProgressionGraphMINOR: UnweightedGraph<String>!
    
    //  Returns the singleton instance
    class var sharedInstance:MusicDataConstants {
        return MusicDataConstantsInstance
    }
    
    private override init() {
        super.init()
        self.buildHarmonicProgressionGraph()
    }
    
    //  All imported progressions MUST be transposed to the key of C
    
    //  maybe it should learn this instead? I'm not sure....
    
    private func buildHarmonicProgressionGraph() {
        self.harmonicProgressionGraphMAJOR = UnweightedGraph<String>()
        
        //  Add chords to a directed graph that follows the rules of harmonic motion
        
        //  Primary Chords
        self.harmonicProgressionGraphMAJOR.addVertex("C")
        self.harmonicProgressionGraphMAJOR.addVertex("Cmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Dm")
        self.harmonicProgressionGraphMAJOR.addVertex("Dm7")
        self.harmonicProgressionGraphMAJOR.addVertex("Em")
        self.harmonicProgressionGraphMAJOR.addVertex("Em7")
        self.harmonicProgressionGraphMAJOR.addVertex("F")
        self.harmonicProgressionGraphMAJOR.addVertex("Fmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("G")
        self.harmonicProgressionGraphMAJOR.addVertex("G7")
        self.harmonicProgressionGraphMAJOR.addVertex("Am")
        self.harmonicProgressionGraphMAJOR.addVertex("Am7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bm")
        self.harmonicProgressionGraphMAJOR.addVertex("Bdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Bdim7")
        
        //  Primary edges
        self.harmonicProgressionGraphMAJOR.addEdge("C", to: "Cmaj7")
        
        // Secondary Chords
        
        //  F major
        self.harmonicProgressionGraphMAJOR.addVertex("C7")
        
        //  G major
        self.harmonicProgressionGraphMAJOR.addVertex("D")
        self.harmonicProgressionGraphMAJOR.addVertex("D7")
        
        //  A minor
        self.harmonicProgressionGraphMAJOR.addVertex("E")
        self.harmonicProgressionGraphMAJOR.addVertex("E7")
        
        // Bb major
        self.harmonicProgressionGraphMAJOR.addVertex("F7")
        
        //  D minor
        self.harmonicProgressionGraphMAJOR.addVertex("A")
        self.harmonicProgressionGraphMAJOR.addVertex("A7")
        
        //  E minor
        self.harmonicProgressionGraphMAJOR.addVertex("B")
        self.harmonicProgressionGraphMAJOR.addVertex("B7")
        
        //
        
        
        
        
        self.harmonicProgressionGraphMAJOR.addVertex("Db")
        self.harmonicProgressionGraphMAJOR.addVertex("Eb")
        self.harmonicProgressionGraphMAJOR.addVertex("F#")
        self.harmonicProgressionGraphMAJOR.addVertex("Ab")
        self.harmonicProgressionGraphMAJOR.addVertex("Bb")
        self.harmonicProgressionGraphMAJOR.addVertex("Cm")
        self.harmonicProgressionGraphMAJOR.addVertex("Dbm")
        self.harmonicProgressionGraphMAJOR.addVertex("Ebm")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Fm")
        self.harmonicProgressionGraphMAJOR.addVertex("F#m")
        self.harmonicProgressionGraphMAJOR.addVertex("Gm")
        self.harmonicProgressionGraphMAJOR.addVertex("Abm")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Bbm")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Cdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Dbdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Ddim")
        self.harmonicProgressionGraphMAJOR.addVertex("Ebdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Edim")
        self.harmonicProgressionGraphMAJOR.addVertex("Fdim")
        self.harmonicProgressionGraphMAJOR.addVertex("F#dim")
        self.harmonicProgressionGraphMAJOR.addVertex("Gdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Abdim")
        self.harmonicProgressionGraphMAJOR.addVertex("Adim")
        self.harmonicProgressionGraphMAJOR.addVertex("Bbdim")
        
        self.harmonicProgressionGraphMAJOR.addVertex("C+")
        self.harmonicProgressionGraphMAJOR.addVertex("Db+")
        self.harmonicProgressionGraphMAJOR.addVertex("D+")
        self.harmonicProgressionGraphMAJOR.addVertex("Eb+")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Db7")
        self.harmonicProgressionGraphMAJOR.addVertex("Eb7")
        self.harmonicProgressionGraphMAJOR.addVertex("F#7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Ab7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bb7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Dbmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Dmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Ebmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Emaj7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("F#maj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Gmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Abmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Amaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bbmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bmaj7")
        self.harmonicProgressionGraphMAJOR.addVertex("Cm7")
        self.harmonicProgressionGraphMAJOR.addVertex("Dbm7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Ebm7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Fm7")
        self.harmonicProgressionGraphMAJOR.addVertex("F#m7")
        self.harmonicProgressionGraphMAJOR.addVertex("Gm7")
        self.harmonicProgressionGraphMAJOR.addVertex("Abm7")
        
        self.harmonicProgressionGraphMAJOR.addVertex("Bbm7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bm7")
        self.harmonicProgressionGraphMAJOR.addVertex("Cdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Dbdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Ddim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Ebdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Edim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Fdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("F#dim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Gdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Abdim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Adim7")
        self.harmonicProgressionGraphMAJOR.addVertex("Bbdim7")
        
        
        
        
        
        
    }
}
