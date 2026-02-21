import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gridly/services/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konto i subskrypcja')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isSignedIn ? 'Status konta: zalogowano' : 'Status konta: niezalogowano',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.isSignedIn
                              ? 'Użytkownik: ${auth.displayName}'
                              : 'Zaloguj się kontem Google, aby przypisać subskrypcję do użytkownika.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.isSignedIn
                              ? 'Plan: ${auth.isPro ? 'PRO aktywny' : 'FREE'}'
                              : 'Plan: FREE',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (auth.errorMessage != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        auth.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: auth.isBusy
                      ? null
                      : (auth.isSignedIn ? auth.refreshProfile : auth.signInWithGoogle),
                  icon: auth.isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(auth.isSignedIn ? Icons.sync : Icons.login),
                  label: Text(auth.isSignedIn ? 'Odśwież status konta' : 'Zaloguj przez Google'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: (!auth.isSignedIn || auth.isBusy) ? null : auth.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Wyloguj'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uwaga: status PRO jest odczytywany z profilu użytkownika. W etapie produkcyjnym powinien być aktualizowany automatycznie po walidacji subskrypcji Google Play po stronie serwera.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
