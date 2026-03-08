import Testing
@testable import EzqrinMobile

@MainActor
struct ScannerViewModelTests {
    @Test func checkInSuccess() async {
        let mockService = MockCheckInService()
        mockService.checkInResult = .success(TestData.checkInResponse)
        let vm = ScannerViewModel(checkInService: mockService, eventId: "event-1")

        await vm.handleScannedCode("qr-code-123")

        #expect(vm.toastState == .success("Jane Smith"))
        #expect(vm.isProcessing == false)
        #expect(mockService.lastQrCode == "qr-code-123")
    }

    @Test func checkInAlreadyCheckedIn() async {
        let mockService = MockCheckInService()
        mockService.checkInResult = .failure(APIError.server(ProblemDetails(
            type: nil, title: "Conflict", status: 409,
            detail: "Already checked in", instance: nil, code: "ALREADY_CHECKED_IN"
        )))
        let vm = ScannerViewModel(checkInService: mockService, eventId: "event-1")

        await vm.handleScannedCode("qr-code-123")

        #expect(vm.toastState == .alreadyCheckedIn)
    }

    @Test func checkInError() async {
        let mockService = MockCheckInService()
        mockService.checkInResult = .failure(APIError.unknown)
        let vm = ScannerViewModel(checkInService: mockService, eventId: "event-1")

        await vm.handleScannedCode("qr-code-123")

        if case .error = vm.toastState {
            // OK
        } else {
            Issue.record("Expected error toast state")
        }
    }

    @Test func ignoresDuplicateWhileProcessing() async {
        let mockService = MockCheckInService()
        // Simulate a slow request
        mockService.checkInResult = .success(TestData.checkInResponse)
        let vm = ScannerViewModel(checkInService: mockService, eventId: "event-1")

        vm.isProcessing = true

        await vm.handleScannedCode("qr-code-123")

        // API should not be called while isProcessing
        #expect(mockService.lastQrCode == nil)
    }
}
