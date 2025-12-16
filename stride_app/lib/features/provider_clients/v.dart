import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/exercise/v.dart';
import 'package:stride_app/features/provider_clients/vm.dart';
import 'package:stride_core/repositories/assignments_repo.dart';

class ProviderClientsListV extends StatelessWidget {
  const ProviderClientsListV({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProviderClientsListVM(
        assignmentsRepo: context.read<AssignmentsRepository>(),
      ),
      child: const _ProviderClientsListContent(),
    );
  }
}

class _ProviderClientsListContent extends StatelessWidget {
  const _ProviderClientsListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProviderClientsListVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.isLoading ? null : viewModel.refresh,
          ),
        ],
      ),
      body: () {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading clients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: viewModel.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!viewModel.hasClients) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No clients assigned',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Clients will appear here once assigned',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.clients.length,
            itemBuilder: (context, index) {
              final client = viewModel.clients[index];
              return _ClientCard(
                clientName: client.name,
                clientStatus: client.status.name,
                client: client,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseV(clientId: client.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      }(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your action here
          // e.g., Navigator.push to add new client screen
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _NewClientButton extends StatelessWidget {
  const _NewClientButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _ClientCard extends StatelessWidget {
  final String clientName;
  final String clientStatus;
  final dynamic client; // ClientUserModel
  final VoidCallback onTap;

  const _ClientCard({
    required this.clientName,
    required this.clientStatus,
    required this.client,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (clientStatus.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: screenHeight * 0.33,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              clientStatus,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icon(
                  //   Icons.arrow_forward_ios,
                  //   size: 20,
                  //   color: Colors.grey[400],
                  // ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: client.email ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: client.profile.phone ?? 'N/A',
                    ),
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Date of Birth',
                      value: client.profile.dateOfBirth ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}