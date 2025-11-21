import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
              SizedBox(width: 12),
              Text('Username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Email: user@example.com'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Placeholder: sign out by returning to login
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
