import 'package:charusat_recruitment/const.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charusat_recruitment/Providers/menu_provider.dart'; // Import the MenuProvider

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Access the MenuProvider using the Consumer widget
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        return Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 5),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 17, 19, 33),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          constraints: const BoxConstraints(maxWidth: 288),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.person_outlined),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name, // Replace with dynamic name from the provider if needed
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        // First set the selected tab
                        menuProvider.setSelectedTab(3); // Profile tab
                        // Then close menu
                        menuProvider.setMenuState(false);
                      },
                      leading: const Icon(
                        Icons.person_outlined,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Profile',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                    const Divider(thickness: 0.5),
                    ListTile(
                      onTap: () {
                        // First set the selected tab (if applicable)
                        menuProvider.setSelectedTab(2);
                        // Then close menu
                        menuProvider.setMenuState(false);
                        // Navigate to settings or any other page if needed
                      },
                      leading: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                    const Divider(thickness: 0.5),
                    ListTile(
                      onTap: () {
                        // First set the selected tab
                        menuProvider.setSelectedTab(0); // Home tab
                        // Then close menu
                        menuProvider.setMenuState(false);
                      },
                      leading: const Icon(
                        Icons.announcement_rounded,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Announcement',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                    const Divider(thickness: 0.5),
                    ListTile(
                      onTap: () {
                        // First set the selected tab
                        menuProvider.setSelectedTab(1); // Company tab
                        // Then close menu
                        menuProvider.setMenuState(false);
                      },
                      leading: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Company Drive',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                    const Divider(thickness: 0.5),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
