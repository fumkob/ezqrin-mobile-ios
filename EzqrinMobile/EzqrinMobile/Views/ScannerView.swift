import SwiftUI

struct ScannerView: View {
    @State private var viewModel: ScannerViewModel

    init(event: Event, checkInService: any CheckInServiceProtocol, eventService: any EventServiceProtocol) {
        _viewModel = State(initialValue: ScannerViewModel(
            event: event,
            checkInService: checkInService,
            eventService: eventService
        ))
    }

    var body: some View {
        ZStack {
            // Camera preview
            QRScannerRepresentable { code in
                Task {
                    await viewModel.handleScannedCode(code)
                }
            }
            .ignoresSafeArea()

            // Overlay
            VStack {
                // Participant count
                if let count = viewModel.event.participantCount, let checked = viewModel.event.checkedInCount {
                    Text("\(checked)/\(count) checked in")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                }

                // Toast
                if viewModel.toastState != .hidden {
                    ToastView(state: viewModel.toastState)
                        .padding(.top, 8)
                }

                Spacer()

                // Scan guide
                if !viewModel.isProcessing {
                    Text("Scan QR code")
                        .font(.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 32)
                }

                if viewModel.isProcessing {
                    ProgressView()
                        .tint(.white)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(viewModel.event.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .animation(.easeInOut(duration: 0.3), value: viewModel.toastState)
    }
}

#if DEBUG
private final class PreviewCheckInService: CheckInServiceProtocol, @unchecked Sendable {
    func checkIn(eventId: String, qrCode: String) async throws -> CheckInResponse {
        throw APIError.unknown
    }
}

private final class PreviewEventService: EventServiceProtocol, @unchecked Sendable {
    func listEvents(page: Int, perPage: Int) async throws -> EventListResponse {
        EventListResponse(data: [], meta: PaginationMeta(page: 1, perPage: 50, total: 0, totalPages: 1))
    }
    func getEvent(eventId: String) async throws -> Event {
        throw APIError.unknown
    }
}

private let previewEvent = Event(
    id: "1", organizerId: "u1", name: "WWDC 2026", description: nil,
    startDate: "2026-06-09T09:00:00Z", endDate: "2026-06-13T18:00:00Z",
    location: "Cupertino", status: .ongoing, participantCount: 300, checkedInCount: 120
)

#Preview {
    NavigationStack {
        ScannerView(
            event: previewEvent,
            checkInService: PreviewCheckInService(),
            eventService: PreviewEventService()
        )
    }
}
#endif
