import 'package:blu_manager/domain/entities/bluetooth_device_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/viewmodel_providers.dart';
import '../widgets/bluetooth_device_card.dart';
import '../widgets/error_dialog.dart';
import 'device_detail_page.dart';
import '../viewmodels/bluetooth_scan_viewmodel.dart';

class BluetoothDevicesPage extends ConsumerStatefulWidget {
  const BluetoothDevicesPage({super.key});

  @override
  ConsumerState<BluetoothDevicesPage> createState() =>
      _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends ConsumerState<BluetoothDevicesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final scanState = ref.watch(bluetoothScanViewModelProvider);
            final vm = ref.read(bluetoothScanViewModelProvider.notifier);
            final hasActiveFilters = scanState.searchQuery.isNotEmpty || scanState.filter != DeviceFilter.all || scanState.sort != DeviceSort.none;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filters & Sorting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Active: '
                          '${scanState.filter != DeviceFilter.all ? scanState.filter.name : ''}'
                          '${scanState.sort != DeviceSort.none ? (scanState.filter != DeviceFilter.all ? ', ' : '') + scanState.sort.name : ''}'
                          '${scanState.searchQuery.isNotEmpty ? '${scanState.filter != DeviceFilter.all || scanState.sort != DeviceSort.none ? ', ' : ''}search' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('Filter by'),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: scanState.filter == DeviceFilter.all,
                            onSelected: (_) => vm.updateFilter(DeviceFilter.all),
                          ),
                          FilterChip(
                            label: const Text('Known Names'),
                            selected: scanState.filter == DeviceFilter.knownName,
                            onSelected: (_) => vm.updateFilter(DeviceFilter.knownName),
                          ),
                          FilterChip(
                            label: const Text('Connected'),
                            selected: scanState.filter == DeviceFilter.connected,
                            onSelected: (_) => vm.updateFilter(DeviceFilter.connected),
                          ),
                          FilterChip(
                            label: const Text('Disconnected'),
                            selected: scanState.filter == DeviceFilter.disconnected,
                            onSelected: (_) => vm.updateFilter(DeviceFilter.disconnected),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Sort by'),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('None'),
                            selected: scanState.sort == DeviceSort.none,
                            onSelected: (_) => vm.updateSort(DeviceSort.none),
                          ),
                          ChoiceChip(
                            label: const Text('Nearest (RSSI)'),
                            selected: scanState.sort == DeviceSort.nearestRssi,
                            onSelected: (_) => vm.updateSort(DeviceSort.nearestRssi),
                          ),
                          ChoiceChip(
                            label: const Text('Name A-Z'),
                            selected: scanState.sort == DeviceSort.nameAsc,
                            onSelected: (_) => vm.updateSort(DeviceSort.nameAsc),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                vm.clearFilters();
                                _searchController.clear();
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bluetoothScanViewModelProvider);
    final scanViewModel = ref.read(bluetoothScanViewModelProvider.notifier);
    final hasFilters = scanState.searchQuery.isNotEmpty || scanState.filter != DeviceFilter.all || scanState.sort != DeviceSort.none;
    final baseBorderColor = hasFilters ? Theme.of(context).colorScheme.secondary : Colors.grey.shade400;
    final focusedColor = Theme.of(context).colorScheme.primary;

    // Show error dialog if there's an error
    if (scanState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            message: scanState.errorMessage!,
            onDismiss: () => scanViewModel.clearError(),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter & Sort',
            onPressed: _openFilterSheet,
          ),
          if (scanState.isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: scanViewModel.startScanning,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: scanViewModel.updateSearch,
                decoration: InputDecoration(
                  hintText: 'Search devices by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: scanState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            scanViewModel.updateSearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: baseBorderColor, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: focusedColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
        ),
      ),
      body: Column(
        children: [
          // Bluetooth Status Banner
          if (!scanState.isBluetoothEnabled)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bluetooth is disabled. Please enable Bluetooth to scan for devices.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Device List
          Expanded(
            child: RefreshIndicator(
              onRefresh: scanViewModel.startScanning,
              child: _buildDeviceList(scanState, scanViewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BluetoothScanState scanState, BluetoothScanViewModel vm) {
    final list = scanState.displayedDevices.isNotEmpty || scanState.searchQuery.isNotEmpty || scanState.filter != DeviceFilter.all || scanState.sort != DeviceSort.none
        ? scanState.displayedDevices
        : scanState.devices;

    if (list.isEmpty) {
      return _buildEmptyState(scanState.isScanning, hasActiveFilters: scanState.searchQuery.isNotEmpty || scanState.filter != DeviceFilter.all || scanState.sort != DeviceSort.none);
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final device = list[index];
        return BluetoothDeviceCard(
          device: device,
          onTap: () => _navigateToDeviceDetail(device),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isScanning, {bool hasActiveFilters = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isScanning
                ? 'Scanning for devices...'
                : hasActiveFilters
                    ? 'No devices match the current search/filter.'
                    : 'No devices found.\nTap the scan button to start searching.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (!isScanning && !hasActiveFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(bluetoothScanViewModelProvider.notifier).startScanning(),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Start Scanning'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDeviceDetail(BluetoothDeviceEntity device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceDetailPage(device: device)),
    );
  }
}
