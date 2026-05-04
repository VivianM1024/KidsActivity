import Foundation
import EventKit

// Bridges our CalendarEvent model to EKEventStore so the user can dump
// registered sessions straight into their Apple Calendar from the Calendar
// tab's Export menu.

@MainActor
final class CalendarExportService {
    enum ExportError: Error, LocalizedError {
        case denied
        case noDefaultCalendar
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .denied:            return "Calendar access is off. Enable it in Settings to add sessions to Apple Calendar."
            case .noDefaultCalendar: return "No default calendar is set in Apple Calendar."
            case .underlying(let e): return e.localizedDescription
            }
        }
    }

    private let store = EKEventStore()

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in
                    cont.resume(returning: granted)
                }
            }
        }
    }

    /// Insert each `CalendarEvent` as an EKEvent on the user's default
    /// calendar. Returns the inserted event identifiers so the caller can
    /// offer Undo.
    func addEvents(
        _ events: [CalendarEvent],
        activitiesById: [String: Activity]
    ) async throws -> [String] {
        guard await requestAccess() else { throw ExportError.denied }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw ExportError.noDefaultCalendar
        }

        var ids: [String] = []
        for e in events {
            guard let activity = activitiesById[e.activityId] else { continue }
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = activity.name
            event.startDate = e.date
            event.endDate = e.date.addingTimeInterval(TimeInterval(e.durationMinutes * 60))

            var locationParts: [String] = [activity.venueName]
            if !activity.location.isEmpty { locationParts.append(activity.location) }
            event.location = locationParts.joined(separator: " — ")

            var notes: [String] = []
            if let d = activity.description, !d.isEmpty { notes.append(d) }
            if let n = e.note, !n.isEmpty { notes.append("Note: \(n)") }
            notes.append("Registration: \(activity.sourceUrl.absoluteString)")
            event.notes = notes.joined(separator: "\n\n")
            event.url = activity.sourceUrl

            do {
                try store.save(event, span: .thisEvent, commit: false)
                if let id = event.eventIdentifier { ids.append(id) }
            } catch {
                // If one save fails, roll back any in-flight changes and
                // surface the underlying error so the caller can show it.
                store.reset()
                throw ExportError.underlying(error)
            }
        }

        do { try store.commit() }
        catch {
            store.reset()
            throw ExportError.underlying(error)
        }
        return ids
    }

    /// Remove events by identifier. Used by the Undo affordance on the
    /// "Added N events" toast.
    func removeEvents(identifiers: [String]) async throws {
        guard await requestAccess() else { throw ExportError.denied }
        for id in identifiers {
            guard let event = store.event(withIdentifier: id) else { continue }
            try store.remove(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }
}
