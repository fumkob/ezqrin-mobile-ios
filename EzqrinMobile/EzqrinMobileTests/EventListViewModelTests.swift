import Testing
@testable import EzqrinMobile

@MainActor
struct EventListViewModelTests {
    @Test func loadEventsSuccess() async {
        let mockService = MockEventService()
        mockService.listEventsResult = .success(TestData.eventListResponse)
        let vm = EventListViewModel(eventService: mockService)

        await vm.loadEvents()

        #expect(vm.events.count == 1)
        #expect(vm.events.first?.name == "Test Event")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func loadEventsFailure() async {
        let mockService = MockEventService()
        mockService.listEventsResult = .failure(APIError.unknown)
        let vm = EventListViewModel(eventService: mockService)

        await vm.loadEvents()

        #expect(vm.events.isEmpty)
        #expect(vm.errorMessage != nil)
    }
}
