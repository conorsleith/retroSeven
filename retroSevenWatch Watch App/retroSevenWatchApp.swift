//
//  retroSevenWatchApp.swift
//  retroSevenWatch Watch App
//
//  Created by Conor Sleith on 10/26/23.
//

import SwiftUI
import Foundation
import ClockKit

@main
struct retroSevenWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreen()
        }
    }
}

class ComplicationController: NSObject, CLKComplicationDataSource {


    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // TODO: Finish implementing this required method.
    }
}
