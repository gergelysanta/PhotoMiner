//
//  TimeProfiler.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 30/12/2022.
//  Copyright © 2022 Gergely Sánta. All rights reserved.
//

import Foundation
import os

enum TimeProfiler {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.trikatz.photominer"

    private static let timingLog = OSLog(subsystem: subsystem, category: "Timing")
    private static let poiLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)

    static let enabled = ProcessInfo.processInfo.environment["INSTRUMENTS_SIGNPOST"] != nil

    struct Signpost {
        let id = OSSignpostID(log: TimeProfiler.timingLog)
        let name: StaticString

        func end() {
            os_signpost(.end, log: TimeProfiler.timingLog, name: name, signpostID: id)
        }
    }

    static func begin(_ name: StaticString, description: String = "") -> Signpost? {
        guard enabled else { return nil }

        let signpost = Signpost(name: name)
        os_signpost(.begin, log: timingLog, name: signpost.name, signpostID: signpost.id, "%@", description)
        return signpost
    }

    static func pointOfInterest(_ description: StaticString) {
        guard enabled else { return }

        let signpostID = OSSignpostID(log: poiLog)
        os_signpost(.event, log: poiLog, name: description, signpostID: signpostID)
    }

}
