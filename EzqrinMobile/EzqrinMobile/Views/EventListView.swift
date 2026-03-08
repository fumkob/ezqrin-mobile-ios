import SwiftUI

struct EventListView: View {
    @State private var viewModel: EventListViewModel
    let onEventSelected: (Event) -> Void

    init(eventService: any EventServiceProtocol, onEventSelected: @escaping (Event) -> Void) {
        _viewModel = State(initialValue: EventListViewModel(eventService: eventService))
        self.onEventSelected = onEventSelected
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.events.isEmpty {
                ProgressView("Loading events...")
            } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadEvents() }
                    }
                }
            } else if viewModel.events.isEmpty {
                ContentUnavailableView(
                    "No Events",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("No events found.")
                )
            } else {
                List(viewModel.events) { event in
                    Button {
                        onEventSelected(event)
                    } label: {
                        EventRow(event: event)
                    }
                }
                .refreshable {
                    await viewModel.loadEvents()
                }
            }
        }
        .navigationTitle("Events")
        .task {
            await viewModel.loadEvents()
        }
    }
}

private struct EventRow: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .font(.headline)
            HStack {
                Label(event.status.capitalized, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(statusColor)
                Spacer()
                if let count = event.participantCount, let checked = event.checkedInCount {
                    Text("\(checked)/\(count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let location = event.location {
                Label(location, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch event.status {
        case "published": .blue
        case "ongoing": .green
        case "completed": .gray
        case "cancelled": .red
        default: .secondary
        }
    }
}

#if DEBUG
private final class PreviewEventService: EventServiceProtocol, @unchecked Sendable {
    var events: [Event] = []
    func listEvents(page: Int, perPage: Int) async throws -> EventListResponse {
        EventListResponse(
            data: events,
            meta: PaginationMeta(page: 1, perPage: 50, total: events.count, totalPages: 1)
        )
    }
}

#Preview("With Events") {
    let service = PreviewEventService()
    service.events = [
        Event(id: "1", organizerId: "u1", name: "WWDC 2026", description: nil,
              startDate: "2026-06-09T09:00:00Z", endDate: "2026-06-13T18:00:00Z",
              location: "Cupertino", status: "published", participantCount: 300, checkedInCount: 120)
    ]
    return NavigationStack {
        EventListView(eventService: service, onEventSelected: { _ in })
    }
}

#Preview("Empty") {
    NavigationStack {
        EventListView(eventService: PreviewEventService(), onEventSelected: { _ in })
    }
}
#endif
