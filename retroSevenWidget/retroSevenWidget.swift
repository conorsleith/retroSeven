//
//  retroSevenWidget.swift
//  retroSevenWidget
//
//  Created by Conor Sleith on 10/25/23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 2 {
            print(hourOffset)
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct retroSevenWidgetEntryView : View {
    @StateObject var stravaData: StravaDataViewModel = StravaDataViewModel()
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Button("Refresh Strava Data") {
                stravaData.fetchStravaActivities()
            }
//            HStack {
//                Text("\(stravaData.currentMileage > 0 ? "\(stravaData.currentMileage)" : "")")
//                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
//                Text("\(stravaData.expiringMileage > 0 ? "\(stravaData.expiringMileage)" : "")")
//                    .foregroundColor(Color.gray) // Grey color
//            }
            HStack {
                Text("\(stravaData.currentMileage)")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("\(stravaData.expiringMileage)")
                    .foregroundColor(Color.gray) // Grey color
            }
//            .font(.largeTitle)
            .padding()
        }
        .onAppear {
            //stravaData.fetchStravaActivities()
////            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { timer in
////                stravaData.fetchStravaActivities()
////            }
        }
        .onReceive(stravaData.$currentMileage) { newCurrentMileage in
            // Handle changes to the first derived number
            print("First Number changed to: \(newCurrentMileage)")
        }
        .onReceive(stravaData.$expiringMileage) { newExpiringMileage in
            // Handle changes to the second derived number
            print("Second Number changed to: \(newExpiringMileage)")
        }
    }
}

struct retroSevenWidget: Widget {
    let kind: String = "retroSevenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            retroSevenWidgetEntryView(entry: entry)
                .padding()
                .background()
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
