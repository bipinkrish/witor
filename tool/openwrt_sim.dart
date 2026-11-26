// An isolated simulator for exercising a dropped response and a timed rollback.
import 'dart:async';
import 'dart:io';
import 'package:witor/router/safe_change.dart';

class SimulatedRadio implements ChannelTransaction {
  SimulatedRadio({this.channel = '3', this.dropReply = false});
  String channel;
  final bool dropReply;
  String? _staged, _original;
  Timer? _timer;
  bool get pending => _timer?.isActive ?? false;
  @override
  Future<String> readChannel(String radio) async => channel;
  @override
  Future<void> stage(String radio, String value) async {
    _staged = value;
  }

  @override
  Future<void> applyWithRollback(Duration window) async {
    _original = channel;
    channel = _staged!;
    _staged = null;
    _timer = Timer(window, () {
      channel = _original!;
    });
    if (dropReply) throw TimeoutException('Simulated radio restart');
  }

  @override
  Future<void> confirm() async {
    _timer?.cancel();
    _original = null;
  }

  @override
  Future<void> revertStaged() async {
    _staged = null;
  }
}

Future<void> main() async {
  final router = SimulatedRadio();
  final outcome = await changeChannel(
    router: router,
    radio: 'radio0',
    original: '3',
    proposed: '1',
    sameRouter: () async => true,
    backup: (radio, original) async {
      stdout.writeln('Backup: $radio = $original');
    },
  );
  stdout.writeln('${outcome.name}: channel ${router.channel}');
}
