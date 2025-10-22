

import 'package:flutter/material.dart';

class ClientBottomBar extends StatelessWidget {
  final int index;
  final Function(int) onTap;

  const ClientBottomBar({
    required this.index,
    required this.onTap,
    super.key
    });

  @override
  BottomNavigationBar build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: index,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 32),
            label: 'New',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.poll),
            label: 'Surveys',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      );
  }
}