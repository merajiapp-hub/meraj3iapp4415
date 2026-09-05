import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../features/auth/admin_login_screen.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return const AdminLoginScreen();
        }
        if (!auth.isAdmin) {
          // If a normal user tries to access admin, show unauthorized or redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Navigator.of(context).pushReplacementNamed('/'); // Redirect to normal app
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child;
      },
    );
  }
}
