//
//  Froggy_HopperTests.swift
//  Froggy HopperTests
//
//  Created by Junaid Dawud on 11/3/25.
//

import Testing
import UIKit

struct Froggy_HopperTests {

    @Test
    func audioResourcesExist() {
        let bgFiles = (1...10).map { "BackgroundMusic\($0)" } + ["eat_sound"]
        for name in bgFiles {
            let url = Bundle.main.url(forResource: name, withExtension: "mp3")
            #expect(url != nil, "Missing audio resource: \(name).mp3")
        }
    }

    @Test
    func imageAssetsExist() {
        let images = ["frog", "lily_pad", "fly1", "fly2", "spider1", "spider2", "ant1", "ant2", "rock1", "rock2", "rock3"]
        for name in images {
            let image = UIImage(named: name)
            #expect(image != nil, "Missing image asset: \(name)")
        }
    }

    @Test
    func bundleDisplayNameIsSet() {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        #expect(displayName == "Froggy Feed!")
    }
}
