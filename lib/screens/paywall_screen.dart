import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gridly/services/auth_provider.dart';
import 'package:gridly/services/monetization_provider.dart';
import 'package:gridly/services/subscription_provider.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gridly PRO')),
      body: Consumer3<AuthProvider, SubscriptionProvider, MonetizationProvider>(
        builder: (context, auth, subscription, monetization, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  monetization.isPro ? 'Masz aktywny plan PRO' : 'Odblokuj Gridly PRO',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PRO odblokowuje funkcje premium i usuwa reklamy. Zakup jest powiązany z kontem sklepu oraz kontem użytkownika.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (!auth.isSignedIn)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Najpierw zaloguj się kontem Google w zakładce Konto, aby prawidłowo przypisać subskrypcję do użytkownika.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (subscription.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        subscription.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: subscription.isLoading ? null : subscription.refreshProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Odśwież ofertę sklepu'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: subscription.isRestoring ? null : subscription.restorePurchases,
                  icon: subscription.isRestoring
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: const Text('Przywróć zakupy'),
                ),
                const SizedBox(height: 12),
                if (subscription.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (!subscription.storeAvailable)
                  const Text('Sklep z subskrypcjami jest obecnie niedostępny na tym urządzeniu.')
                else if (subscription.products.isEmpty)
                  const Text('Brak aktywnych produktów abonamentowych. Sprawdź konfigurację w Google Play Console.')
                else
                  ...subscription.products.map(
                    (product) => Card(
                      child: ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.description),
                        trailing: ElevatedButton(
                          onPressed: subscription.isPurchaseInProgress || !auth.isSignedIn
                              ? null
                              : () => subscription.buy(product),
                          child: Text(product.price),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Uwaga: w wersji produkcyjnej status PRO powinien być finalnie potwierdzany serwerowo (RTDN + walidacja zakupu).',
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
