import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    
    var body: some View {
        SearchableView(
            wrappedView: DeviceListContentView(viewModel: viewModel),
            searchText: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            isFilteredListEmpty: viewModel.isFilteredDevicesEmpty,
            hasNetworkConnection: $viewModel.hasNetworkConnection
        )
    }
}

struct DeviceListContentView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    @State private var selectedViewModel: DeviceCenterItemViewModel?
    
    var body: some View {
        ListViewContainer(
            selectedItem: $selectedViewModel,
            hasNetworkConnection: $viewModel.hasNetworkConnection
        ) {
            PlaceholderContainerView(
                isLoading: $viewModel.isLoadingPlaceholderVisible,
                content: content,
                placeholder: PlaceholderContentView(placeholderRow: placeholderRowView)
            )
        }
        .task {
            viewModel.updateInternetConnectionStatus()
        }
    }
    
    private var content: some View {
        List {
            if viewModel.isFiltered {
                ForEach(viewModel.filteredDevices) { deviceViewModel in
                    DeviceCenterItemView(
                        viewModel: deviceViewModel,
                        selectedViewModel: $selectedViewModel
                    )
                    .listRowInsets(EdgeInsets())
                }
            } else {
                Section(header: Text(Strings.Localizable.Device.Center.Current.Device.title)) {
                    if let currentDeviceVM = viewModel.currentDevice {
                        DeviceCenterItemView(
                            viewModel: currentDeviceVM,
                            selectedViewModel: $selectedViewModel
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                if viewModel.otherDevices.isNotEmpty {
                    Section(header: Text(Strings.Localizable.Device.Center.Other.Devices.title)) {
                        ForEach(viewModel.otherDevices) { deviceViewModel in
                            DeviceCenterItemView(
                                viewModel: deviceViewModel,
                                selectedViewModel: $selectedViewModel
                            )
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background()
        .onReceive(viewModel.refreshDevicesPublisher) { _ in
            Task {
                let userDevices = await self.viewModel.fetchUserDevices()
                self.viewModel.arrangeDevices(userDevices)
                self.viewModel.updateInternetConnectionStatus()
            }
        }
        .throwingTask {
            try await viewModel.startAutoRefreshUserDevices()
        }
    }
    
    private var placeholderRowView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 112, height: 16)

                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 175, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 20, leading: 12, bottom: 0, trailing: 12))
        .shimmering()
    }
}
