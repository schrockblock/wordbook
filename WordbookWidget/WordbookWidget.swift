//
//  WordbookWidget.swift
//  WordbookWidget
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

struct WordbookWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            ComplicationCircular()
        @unknown default:
            //mandatory as there are more widget families as in lockscreen widgets etc
            Text("Not an implemented widget yet")
        }
    }
}

struct ComplicationCircular : View {
    var body: some View {
         Image(systemName: "plus")
            .widgetLabel("Test")
             .widgetAccentable(true)
             .unredacted()
    }
}

struct WordbookWidget: Widget {
    let kind: String = "WordbookWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WordbookWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Add word")
        .description("This is an example widget.")
    }
}

struct WordbookWidget_Previews: PreviewProvider {
    static var previews: some View {
        WordbookWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
