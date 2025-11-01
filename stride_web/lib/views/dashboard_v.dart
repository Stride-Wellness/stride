import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/models/user_m.dart';
import 'package:stride_web/views/clients_v.dart';
import 'package:stride_web/views/divisions_v.dart';
import 'package:stride_web/views/providers_v.dart';
// import 'package:stride_web/views/providers_v.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthStateController>();

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
                label: Text('Providers'),
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
        return const ProvidersView();
      case 2:
        return const ClientsView();
      default:
        return const DivisionsView();
    }
  }
}

