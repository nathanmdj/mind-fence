import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../bloc/block_setup_bloc.dart';
import '../bloc/block_setup_state.dart';
import 'app_list_item.dart';

class SearchableAppsModal extends StatefulWidget {
  final String title;
  final List<BlockedApp> initialApps;
  final bool showOnlyMostUsed;
  final BlockSetupBloc blockSetupBloc;
  
  const SearchableAppsModal({
    super.key,
    required this.title,
    required this.initialApps,
    required this.blockSetupBloc,
    this.showOnlyMostUsed = false,
  });

  @override
  State<SearchableAppsModal> createState() => _SearchableAppsModalState();
}

class _SearchableAppsModalState extends State<SearchableAppsModal> {
  final TextEditingController _searchController = TextEditingController();
  List<BlockedApp> _filteredApps = [];
  
  @override
  void initState() {
    super.initState();
    _filteredApps = widget.initialApps;
    _searchController.addListener(_filterApps);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = widget.initialApps;
      } else {
        _filteredApps = widget.initialApps.where((app) {
          return app.name.toLowerCase().contains(query) ||
                 app.packageName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.blockSetupBloc,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<BlockSetupBloc, BlockSetupState>(
                  builder: (context, state) {
                    if (state is BlockSetupLoaded) {
                      // Get updated apps from state to reflect toggle changes
                      final updatedFilteredApps = _filteredApps.map((app) {
                        final updatedApp = state.installedApps.firstWhere(
                          (installedApp) => installedApp.packageName == app.packageName,
                          orElse: () => app,
                        );
                        return updatedApp;
                      }).toList();
                      
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: updatedFilteredApps.length,
                        itemBuilder: (context, index) {
                          final app = updatedFilteredApps[index];
                          return AppListItem(app: app);
                        },
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        return AppListItem(app: app);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}