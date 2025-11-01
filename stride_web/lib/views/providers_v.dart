import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_core/view_models/user_vm.dart';

class ProvidersView extends StatelessWidget {
  const ProvidersView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UsersViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProvidersHeader(viewModel: viewModel),
          const SizedBox(height: 24),
          _ProvidersBody(viewModel: viewModel),
        ],
      ),
    );
  }
}

// ============================================================================
// Header Section
// ============================================================================

class _ProvidersHeader extends StatelessWidget {
  final UsersViewModel viewModel;

  const _ProvidersHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Providers',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${viewModel.providerCount} active providers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        Row(
          children: [
            // Search bar
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search providers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: viewModel.setSearchQuery,
              ),
            ),
            const SizedBox(width: 12),
            // Filter button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Show filter dialog
              },
              icon: const Icon(Icons.filter_list),
              label: const Text('Filter'),
            ),
            const SizedBox(width: 8),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: viewModel.isLoading ? null : viewModel.refresh,
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            // Add button
            ElevatedButton.icon(
              onPressed: () {
                _showAddProviderDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Provider'),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddProviderDialog(BuildContext context) {
    // TODO: Implement add provider dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Provider'),
        content: const Text('Add provider form coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Body Section
// ============================================================================

class _ProvidersBody extends StatelessWidget {
  final UsersViewModel viewModel;

  const _ProvidersBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.refresh,
      );
    }

    if (!viewModel.hasProviders) {
      return const _EmptyState();
    }

    return _ProvidersTable(
      providers: viewModel.providers,
      viewModel: viewModel,
    );
  }
}

// ============================================================================
// Error State
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading providers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Empty State
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No providers yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first provider to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Providers Table
// ============================================================================

class _ProvidersTable extends StatelessWidget {
  final List<ProviderUserModel> providers;
  final UsersViewModel viewModel;

  const _ProvidersTable({required this.providers,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Division', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Clients', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: providers.map((provider) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          provider.name.isNotEmpty
                              ? provider.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(provider.name),
                    ],
                  ),
                ),
                DataCell(Text(provider.email)),
                DataCell(
                  Wrap(
                    spacing: 4,
                    children: provider.providerRole.map((role) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(role).withAlpha(30),
                          ),
                        ),
                        child: Text(
                          role.name.toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                DataCell(
                  Text(provider.divisionId),
                ),
                DataCell(
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        viewModel
                            .getClientCountForProvider(provider.id)
                            .toString(),
                      ),
                    ],
                  ),
                ),
                DataCell(_StatusBadge(status: provider.status.name)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () {
                          // TODO: Edit provider
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final confirmed = await _showDeleteConfirmation(
                            context,
                            provider.name,
                          );
                          if (confirmed && context.mounted) {
                            final success = await viewModel.deleteUser(
                              provider.id,
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${provider.name} deleted successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getRoleColor(ProviderRole role) {
    switch (role) {
      case ProviderRole.manager:
        return Colors.purple;
      case ProviderRole.admin:
        return Colors.orange;
      case ProviderRole.lw:
        return Colors.blue;
      case ProviderRole.psw:
        return Colors.blue;
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ============================================================================
// Status Badge
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}