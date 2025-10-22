import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_web/views/clients_v.dart';
import 'package:stride_web/views/divisions_v.dart';
import 'package:stride_web/views/employees_v.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateViewController>();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Divisions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Employees'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Clients'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
              ),
            ],
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == 3) {
                // Sign out
                authState.signOut();
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: SizedBox(
              height: double.infinity,
              child: _buildContent()
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DivisionsView();
      case 1:
        return const EmployeesView();
      case 2:
        return const ClientsView();
      default:
        return const DivisionsView();
    }
  }
}

// ============================================================================
// Tab Content Widgets
// ============================================================================

class _EmployeesContent extends StatelessWidget {
  const _EmployeesContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employees',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add new employee
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Employee'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder for employees list
          const Placeholder(fallbackHeight: 400),
        ],
      ),
    );
  }
}

class _ClientsContent extends StatelessWidget {
  const _ClientsContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clients',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add new client
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Client'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Placeholder for clients list
          const Placeholder(fallbackHeight: 400),
        ],
      ),
    );
  }
}