import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:gridly/services/app_settings_provider.dart';
import 'package:gridly/services/auth_provider.dart';
import 'package:gridly/services/monetization_provider.dart';
import 'package:gridly/widgets/pdf_report_dialog.dart';
import 'package:gridly/widgets/export_project_dialog.dart';
import 'package:gridly/widgets/ad_banner_placeholder.dart';
import 'package:gridly/widgets/main_mobile_nav_bar.dart';
import 'package:gridly/theme/grid_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gridly Electrical Checker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Profil i ustawienia',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Debug monetizacji',
              onPressed: () => _showMonetizationDebugSheet(context),
            ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? const MainMobileNavBar(currentRoute: '/dashboard')
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountSummary(context),
              const SizedBox(height: 12),

              // Main features section
              _buildSectionHeader(context, 'Główne funkcje', '⚡'),
              const SizedBox(height: 8),
              _buildQuickButtonsGrid(context, isMobile),
              const SizedBox(height: 20),

              // Export section
              _buildSectionHeader(
                context,
                'Projekt',
                '💾',
                showProBadge: true,
              ),
              const SizedBox(height: 8),
              _buildExportButtons(context, isMobile),
              const SizedBox(height: 20),
              const AdBannerPlaceholder(slotId: 'dashboard_bottom'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary(BuildContext context) {
    return Consumer2<AuthProvider, MonetizationProvider>(
      builder: (context, auth, monetization, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  auth.isSignedIn ? Icons.verified_user : Icons.person_outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isSignedIn
                            ? 'Konto: ${auth.displayName}'
                            : 'Konto: niezalogowano',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Plan: ${monetization.isPro ? 'PRO aktywny' : 'FREE'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Profil'),
                ),
                if (!monetization.isPro)
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/paywall'),
                    icon: const Icon(Icons.workspace_premium, size: 16),
                    label: const Text('PRO'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String icon, {
    bool showProBadge = false,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (showProBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber[700],
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'PRO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickButtonsGrid(BuildContext context, bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.2 : 1.4,
      children: [
        _buildDashboardButton(
          context,
          'Struktura rozdzielnic zasilania budowlanego',
          Icons.account_tree,
          () => Navigator.pushNamed(context, '/construction-power'),
        ),
        _buildDashboardButton(
          context,
          'Analiza obwodu elektrycznego',
          Icons.assessment,
          () => Navigator.pushNamed(context, '/audit'),
        ),
        _buildDashboardButton(
          context,
          'Multitool',
          Icons.build,
          () => Navigator.pushNamed(context, '/multitool'),
        ),
      ],
    );
  }



  Widget _buildDashboardButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GridTheme.electricYellow,
                Colors.amber[700]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: GridTheme.electricYellow.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: GridTheme.deepNavy,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: GridTheme.deepNavy,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportButtons(BuildContext context, bool isMobile) {
    return Consumer2<MonetizationProvider, AppSettingsProvider>(
      builder: (context, monetization, settings, _) {
        final isPro = monetization.isPro;

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showPdfReportDialog(context),
                icon: const Icon(Icons.description),
                label: Text(isMobile ? 'PDF' : 'Generuj PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!isPro) {
                    _showProRequiredSnackBar(context);
                    if (settings.autoOpenPaywallForLockedFeatures) {
                      Navigator.pushNamed(context, '/paywall');
                    }
                    return;
                  }

                  showExportProjectDialog(
                    context,
                    auditData: {},
                    calculatorData: {},
                    labelData: {},
                  );
                },
                icon: Icon(isPro ? Icons.save : Icons.lock),
                label: Text(isMobile ? 'PRO' : 'Eksportuj Projekt (PRO)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProRequiredSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ta funkcja jest dostępna w wersji PRO.'),
      ),
    );
  }

  void _showMonetizationDebugSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer<MonetizationProvider>(
            builder: (context, monetization, _) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug monetizacji',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tryb PRO'),
                      value: monetization.isPro,
                      onChanged: (value) => monetization.setPro(value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reklamy włączone'),
                      value: monetization.adsEnabled,
                      onChanged: (value) => monetization.setAdsEnabled(value),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

