import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gridly/services/app_settings_provider.dart';
import 'package:gridly/services/auth_provider.dart';
import 'package:gridly/services/monetization_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;

  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _companyController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _seedFromAuth(AuthProvider auth) {
    if (_seeded) {
      return;
    }
    _displayNameController.text = auth.displayName;
    _companyController.text = auth.companyName;
    _phoneController.text = auth.phoneNumber;
    _seeded = true;
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await auth.updateProfileData(
      displayName: _displayNameController.text,
      companyName: _companyController.text,
      phoneNumber: _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    if (auth.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dane profilu zostały zapisane.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil i ustawienia')),
      body: Consumer3<AuthProvider, AppSettingsProvider, MonetizationProvider>(
        builder: (context, auth, settings, monetization, _) {
          _seedFromAuth(auth);

          if (!auth.isSignedIn) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Aby edytować dane profilu i ustawienia konta, zaloguj się przez Google.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: auth.isBusy ? null : auth.signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Zaloguj przez Google'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dane użytkownika',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nazwa użytkownika',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'To pole jest wymagane.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            initialValue: auth.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail konta',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Firma (opcjonalnie)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefon (opcjonalnie)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: auth.isBusy ? null : () => _saveProfile(auth),
                            icon: auth.isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Zapisz dane'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ustawienia aplikacji',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Pokazuj reklamy w aplikacji'),
                          subtitle: const Text(
                            'Możesz wyłączyć reklamy niezależnie od statusu konta.',
                          ),
                          value: settings.adsEnabled,
                          onChanged: (value) async {
                            await settings.setAdsEnabled(value);
                            monetization.setAdsEnabled(value);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Auto-otwieraj paywall dla funkcji PRO'),
                          subtitle: const Text(
                            'Przy próbie wejścia w funkcję PRO aplikacja przeniesie od razu do oferty.',
                          ),
                          value: settings.autoOpenPaywallForLockedFeatures,
                          onChanged: settings.setAutoOpenPaywallForLockedFeatures,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aktualny plan: ${monetization.isPro ? 'PRO aktywny' : 'FREE'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/paywall'),
                          child: const Text('Zarządzaj'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
