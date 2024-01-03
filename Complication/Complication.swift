//
//  Complication.swift
//  Complication
//
//  Created by Elliot Schrock on 9/21/23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct ComplicationEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            ComplicationCircular()
        case .accessoryCorner:
            ComplicationCircular()
        case .accessoryRectangular:
            ComplicationCircular()
        case .accessoryInline:
            ComplicationCircular()
        @unknown default:
            //mandatory as there are more widget families as in lockscreen widgets etc
            ComplicationCircular()
        }
    }
}

struct ComplicationCircular : View {
    var body: some View {
        HStack {
            Image(systemName: "mic.badge.plus").padding()
        }.padding()
        .background(Circle().stroke(Color.primary))
        .containerBackground(for: .widget, content: {
            Circle().stroke(Color.primary)
        })
             .widgetAccentable(true)
             .unredacted()
    }
}

@main
struct Complication: Widget {
    let kind: String = "Complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Add word")
        .description("This is an example widget.")
    }
}

struct Complication_Previews: PreviewProvider {
    static var previews: some View {
        ComplicationEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
