import 'dart:async';

/// A channel change on OpenWrt is staged under the current ubus session.
/// Unconfirmed changes expire on the router, even if the app is killed.
abstract interface class ChannelTransaction {
  Future<String> readChannel(String radio);
  Future<void> stage(String radio, String channel);
  Future<void> applyWithRollback(Duration timeout);
  Future<void> confirm();
  Future<void> revertStaged();
}

enum ChangeOutcome { unchanged, verified, awaitingRouterRollback }

Future<ChangeOutcome> changeChannel({
  required ChannelTransaction router,
  required String radio,
  required String original,
  required String proposed,
  required Future<bool> Function() sameRouter,
  required Future<void> Function(String radio, String original) backup,
  Duration rollbackWindow = const Duration(seconds: 90),
  Duration pollInterval = const Duration(seconds: 2),
}) async {
  final channel = int.tryParse(proposed);
  if (proposed != 'auto' && (channel == null || channel < 1 || channel > 14)) {
    throw ArgumentError.value(proposed, 'proposed');
  }
  if (!await sameRouter() || await router.readChannel(radio) != original) {
    throw StateError('The router or original setting changed.');
  }
  if (original == proposed) return ChangeOutcome.unchanged;
  await backup(radio, original);
  if (!await sameRouter()) throw StateError('The device changed networks.');
  try {
    await router.stage(radio, proposed);
  } catch (_) {
    if (await sameRouter()) await router.revertStaged();
    rethrow;
  }
  final elapsed = Stopwatch()..start();
  try {
    await router.applyWithRollback(rollbackWindow);
  } on TimeoutException {
    return ChangeOutcome.awaitingRouterRollback;
  } on Exception {
    // An interrupted request is ambiguous. Never confirm an unacknowledged
    // apply based only on UCI's staged value.
    return ChangeOutcome.awaitingRouterRollback;
  }
  final deadline = rollbackWindow - const Duration(seconds: 12);
  while (elapsed.elapsed < deadline) {
    if (await sameRouter()) {
      try {
        if (await router.readChannel(radio) == proposed &&
            await sameRouter() &&
            elapsed.elapsed < deadline) {
          await router.confirm();
          return ChangeOutcome.verified;
        }
      } on Exception {
        /* A radio restart can briefly take ubus offline. */
      }
    }
    await Future<void>.delayed(pollInterval);
  }
  return ChangeOutcome.awaitingRouterRollback;
}
