import 'package:flutter_test/flutter_test.dart';
import 'package:witor/router/safe_change.dart';
import '../tool/openwrt_sim.dart';

void main() {
  test(
    'successful channel change saves the original before staging and confirms only the verified channel',
    () async {
      final device = SimulatedRadio();
      String? saved;
      final outcome = await changeChannel(
        router: device,
        radio: 'radio0',
        original: '3',
        proposed: '1',
        sameRouter: () async => true,
        backup: (_, v) async {
          expect(device.channel, '3');
          saved = v;
        },
      );
      expect(saved, '3');
      expect(outcome, ChangeOutcome.verified);
      expect(device.pending, isFalse);
    },
  );
  test(
    'a dropped apply reply lets the router restore its original channel',
    () async {
      final device = SimulatedRadio(dropReply: true);
      final outcome = await changeChannel(
        router: device,
        radio: 'radio0',
        original: '3',
        proposed: '6',
        sameRouter: () async => true,
        backup: (_, _) async {},
        rollbackWindow: const Duration(milliseconds: 30),
      );
      expect(outcome, ChangeOutcome.awaitingRouterRollback);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(device.channel, '3');
    },
  );
  test('roaming before staging prevents a write', () async {
    int checks = 0;
    final device = SimulatedRadio();
    await expectLater(
      changeChannel(
        router: device,
        radio: 'radio0',
        original: '3',
        proposed: '11',
        sameRouter: () async => ++checks == 1,
        backup: (_, _) async {},
      ),
      throwsStateError,
    );
    expect(device.channel, '3');
    expect(device.pending, isFalse);
  });
}
