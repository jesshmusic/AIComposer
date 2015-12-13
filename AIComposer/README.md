# AIComposer

## How to compile and run the preexisting data file:

1. Press the Build and Run button in the upper left-hand corner to start the application up.
2. Under 'File' select 'Open...'.
3. Open "ResultsDataSet.aicomp" located in the projects folder.
4. To listen to the playback of a preexisting composition, select it in the table and click 'Play'.
5. To compose a new piece, enter a number of Genes (20-60 work best) and generations (300-500 work best, BUT take a really long time)
 * Click "COMPOSE". 
 * The field will display information as it runs the algorithm.


Note:

'Compose' will not work in a new file because it requires MIDI files formatted in a specific way as input for both Melodic and Chord Progressions.

## Controller Classes
* `CompositionController.swift`: this contains all of the functions involved with creating music. 
 * Two genetic algorithms are implemented:
  * Main theme creation genetic algorithm 
  * Composition creation genetic algorithm
 * Also contains methods to generate instrument presets and random names.
 * Has `struct` definitions for `DesiredResults` and `CompositionWeights`


## The Music object structure
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