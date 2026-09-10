import 'dart:async';

import 'package:flutter/material.dart';

import '../../../API/token.api.dart';
import 'bpartner_repository.dart';

class BPartnerSyncController extends ChangeNotifier {
  BPartnerSyncController._();

  static final BPartnerSyncController instance = BPartnerSyncController._();

  bool isRunning = false;
  bool isStopping = false;
  int processed = 0;
  int total = 0;
  int currentPage = 0;
  int failedPages = 0;
  String? error;
  bool _stopRequested = false;
  int? _clientId;

  double get progress => total <= 0 ? 0 : (processed / total).clamp(0, 1);

  Future<void> start({required BuildContext context}) async {
    if (isRunning) return;
    final nextClient = Token.client;
    final canResume = _clientId == nextClient &&
        (isStopping || error != null || (total > 0 && processed < total));
    if (!canResume) {
      processed = 0;
      total = 0;
      currentPage = 0;
      failedPages = 0;
    }
    _clientId = nextClient;
    isRunning = true;
    isStopping = false;
    error = null;
    _stopRequested = false;
    notifyListeners();

    try {
      var hasMore = true;
      while (hasMore && !_stopRequested) {
        try {
          final page = await BPartnerRepository.instance.refreshPage(
            context: context,
            pageIndex: currentPage,
          );
          total = page.rowCount;
          processed = ((currentPage + 1) * bPartnerPageSize).clamp(0, total);
          hasMore = page.hasMore;
          currentPage++;
          error = null;
        } catch (exception) {
          failedPages++;
          error = exception.toString();
          hasMore = false;
        }
        notifyListeners();
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      isRunning = false;
      isStopping = false;
      notifyListeners();
    }
  }

  void stop() {
    if (!isRunning) return;
    _stopRequested = true;
    isStopping = true;
    notifyListeners();
  }

  Future<void> stopAndWait() async {
    stop();
    while (isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void cancelForSessionChange() {
    _stopRequested = true;
    isStopping = isRunning;
    BPartnerRepository.instance.clearMemory();
    notifyListeners();
  }
}
