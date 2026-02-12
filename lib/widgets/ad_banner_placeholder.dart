import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/services/monetization_provider.dart';

class AdBannerPlaceholder extends StatelessWidget {
  final String slotId;

  const AdBannerPlaceholder({
    super.key,
    required this.slotId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationProvider>(
      builder: (context, monetization, _) {
        if (!monetization.shouldShowAds) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 64,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            'Miejsce reklamowe • $slotId',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
