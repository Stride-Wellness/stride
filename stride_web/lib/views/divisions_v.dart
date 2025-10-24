import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/models/division_m.dart';
import 'package:stride_core/view_models/divisions_vm.dart';

class DivisionsView extends StatelessWidget {
  const DivisionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DivisionsViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DivisionsHeader(viewModel: viewModel),
          const SizedBox(height: 24),
          _DivisionsBody(viewModel: viewModel),
        ],
      ),
    );
  }
}

// ============================================================================
// Header Section
// ============================================================================

class _DivisionsHeader extends StatelessWidget {
  final DivisionsViewModel viewModel;

  const _DivisionsHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Divisions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${viewModel.activeDivisions.length} active divisions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: viewModel.isLoading ? null : viewModel.refresh,
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Show create division dialog
                _showCreateDivisionDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Division'),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateDivisionDialog(BuildContext context) {
    // TODO: Implement create division dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Division'),
        content: const Text('Create division form coming soon...'),
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

class _DivisionsBody extends StatelessWidget {
  final DivisionsViewModel viewModel;

  const _DivisionsBody({required this.viewModel});

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

    if (!viewModel.hasDivisions) {
      return const _EmptyState();
    }

    return _DivisionsGrid(divisions: viewModel.activeDivisions);
  }
}

// ============================================================================
// States
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
              'Error loading divisions',
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
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No divisions yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first division to get started',
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
// Divisions Grid
// ============================================================================

class _DivisionsGrid extends StatelessWidget {
  final List<DivisionModel> divisions;

  const _DivisionsGrid({required this.divisions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: divisions.length,
          itemBuilder: (context, index) {
            return _DivisionCard(division: divisions[index]);
          },
        );
      },
    );
  }
}

// ============================================================================
// Division Card
// ============================================================================

class _DivisionCard extends StatelessWidget {
  final DivisionModel division;

  const _DivisionCard({required this.division});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DivisionsViewModel>();
    final providerCount = viewModel.getProviderCount(division.id);
    final clientCount = viewModel.getClientCount(division.id);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to division details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      division.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: division.status),
                ],
              ),
              const SizedBox(height: 8),

              const Spacer(),

              // Stats
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    icon: Icons.people_outline,
                    label: 'Providers',
                    value: providerCount.toString(),
                  ),
                  _StatItem(
                    icon: Icons.person_outline,
                    label: 'Clients',
                    value: clientCount.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'deleted':
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}