//
//  retroSevenWidget.swift
//  retroSevenWidget
//
//  Created by Conor Sleith on 10/25/23.
//

import WidgetKit
import SwiftUI
import Foundation
import Combine

struct Provider: TimelineProvider {
    private var stravaData: StravaDataViewModel = StravaDataViewModel()
    @ObservedObject var auth: AuthViewModel = AuthViewModel()
    private var cancellables = Set<AnyCancellable>()

    func placeholder(in context: Context) -> MileageEntry {
        print("placeholder")
        return MileageEntry(date: Date(), currentMileage: 420, expiringMileage: 69)
    }

    func getSnapshot(in context: Context, completion: @escaping (MileageEntry) -> ()) {
        print("getSnapshot")
        let entry = MileageEntry(date: Date(), currentMileage: 420, expiringMileage: 69)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MileageEntry>) -> ()) {
        print("getTimeline")
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        auth.refresh { result in
            Task{
                var currentMileage: Int
                var expiringMileage: Int
                (currentMileage, expiringMileage) = await stravaData.fetchStravaActivities()
                let entry = MileageEntry(date: Date(), currentMileage: currentMileage, expiringMileage: expiringMileage)
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
                completion(timeline)
            }
        }
    }
}

struct MileageEntry: TimelineEntry {
    let date: Date
    let currentMileage: Int
    let expiringMileage: Int
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct retroSevenWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {

            HStack {
                Text("\(entry.currentMileage)")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("\(entry.expiringMileage)")
                    .foregroundColor(Color.gray) // Grey color
            }
            .font(.largeTitle)
            .padding()
        }
    }
}

struct retroSevenWidget: Widget {
    let kind: String = "retroSevenWidget"
    @ObservedObject var authViewModel = AuthViewModel()
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                retroSevenWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                retroSevenWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    retroSevenWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
