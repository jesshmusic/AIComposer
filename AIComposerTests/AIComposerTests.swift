//
//  AIComposerTests.swift
//  AIComposerTests
//
//  Created by Jess Hendricks on 10/30/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import XCTest
@testable import AIComposer

class AIComposerTests: XCTestCase {
    
    var testDataSet: MusicDataSet!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.testDataSet = MusicDataSet()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFileImport() {
        self.testDataSet.addNewMIDIFile("Bach-Sample-WithCC20.mid")
        print(self.testDataSet.getDataString())
        XCTAssertEqual(self.testDataSet.musicSnippets.count, 5, "Oops")
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
