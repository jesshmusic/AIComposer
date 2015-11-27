# AIComposer
WIP: AIComposer will be able to collect data from MIDI files, which it will use to compose simple music.

## Instructions for running the genetic algorithm
1. In Xcode open `AIComposer.xcodeproj`
2. Click Build & Run
3. In AIComposer open `GeneticTest1.aicomp`
4. If it is not already selected, click the *Composer* tab
5. In the composer tab, clicking a selection from the table and `PLAY` will play that selection.
6. To run the algorithm and create a new composition, click `Compose` at the bottom.
  * The algorithm is not implemented yet in its entirety
  * It currently just does the initialization phase
  * The randomly generated compositon with the best initial fitness is chosen.

## Things that need to be completed:
* In `ComposerController.swift` the genetic algorithm needs to be completed.
  * Above the code window in Xcode, there is a breadcrumb path.
  * To the right of the current file name, if you click the bar all of the function calls and variables will display along with several **TODO** labels.
  
## The Music object structure
Each "Gene" in the genetic algorithm is constructed with the following hierarchy:
* `CompositionGene`
  * `fitness` (`Double`)
  * `MusicComposition`: an complete piece of music with 4 instruments.
    * `[MusicPart]`: an array consisting of the four instrument melodies
      * `[MusicMeasure]`: an array of all of the measures in that instrument's part.
        * `[MusicNote]`: an array of all of the individual notes in each measure.
          * `MusicTimeStamp`: a `Double` representing where in the music sequence the note starts. (1.0 is the length of a quarter note)
          * `MIDINoteMessage`: the actual MIDI message for the note.
            * `channel: UInt8`: the MIDI channel number. (0-16)
            * `note: UInt8`: the MIDI note number. (0-127)
            * `velocity: UInt8`: the velocity (loudness) of the note. (0-127)
            * `releaseVelocity: UInt8`: The velocity after the note is released. Always set to 0.
            * `duration: Float32`: The length of the note in a MIDI sequence.

**NOTE:** For the *Mutation* part, we can just have a function that performs a variation on measures in a part. *Use:* `applyRandomPermutationToMeasure()` *to accomplish this.* Also, crossover should probably exchange measures between `CompositionGene` objects. I will make sure that copying measures works because I have noticed that objects from the MIDI framework are pointers that need to be recreated to be copied properly. If necessary, I can write methods in `MusicComposition.swift` to return a copy or even swap a measure.
