import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../localization/app_locale.dart';
import '../product/product_sync_controller.dart';
import 'bpartner_sync_controller.dart';

class BPartnerSyncOverlay extends StatefulWidget {
  const BPartnerSyncOverlay({super.key});

  @override
  State<BPartnerSyncOverlay> createState() => _BPartnerSyncOverlayState();
}

class _BPartnerSyncOverlayState extends State<BPartnerSyncOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = BPartnerSyncController.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, ProductSyncController.instance]),
      builder: (context, _) {
        if (!controller.isRunning && controller.error == null) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;
        final progressLabel = controller.total > 0
            ? '${controller.processed} / ${controller.total}'
            : AppLocale.preparingSync.getString(context);
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                ProductSyncController.instance.isRunning || ProductSyncController.instance.error != null ? 220 : 76,
              ),
              child: Material(
                elevation: 10,
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _expanded ? 310 : 210,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (controller.isRunning)
                              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                            else
                              Icon(Icons.sync_problem, color: colors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocale.syncingCustomers.getString(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(_expanded ? Icons.expand_more : Icons.expand_less),
                          ],
                        ),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(value: controller.total > 0 ? controller.progress : null),
                        const SizedBox(height: 6),
                        Text(progressLabel, style: Theme.of(context).textTheme.bodySmall),
                        if (_expanded) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${AppLocale.page.getString(context)} ${controller.currentPage + 1}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (controller.error != null)
                            Text(AppLocale.customerSyncError.getString(context), style: TextStyle(color: colors.error)),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: controller.isRunning
                                  ? (controller.isStopping ? null : controller.stop)
                                  : () => controller.start(context: context),
                              icon: Icon(controller.isRunning ? Icons.stop_circle_outlined : Icons.refresh),
                              label: Text(
                                controller.isStopping
                                    ? AppLocale.stopping.getString(context)
                                    : controller.isRunning
                                    ? AppLocale.stop.getString(context)
                                    : AppLocale.retry.getString(context),
                              ),
                              style: TextButton.styleFrom(foregroundColor: colors.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
