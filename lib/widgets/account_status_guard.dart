import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/account_suspended_screen.dart';

class AccountStatusGuard extends StatelessWidget {
  final Widget child;

  const AccountStatusGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.user != null && auth.isAccountSuspended) {
      return const AccountSuspendedScreen();
    }

    return child;
  }
}
