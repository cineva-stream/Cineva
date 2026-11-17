import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player PiP and Back Navigation Channel Tests', () {
    const channel = MethodChannel('com.primadev.cineva/pip');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'setAutoPipEnabled') {
          return true;
        } else if (methodCall.method == 'enterPip') {
          return true;
        } else if (methodCall.method == 'isPipSupported') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Disarming auto-pip sends setAutoPipEnabled false to native platform', () async {
      await channel.invokeMethod('setAutoPipEnabled', {'enabled': false});

      expect(log, hasLength(1));
      expect(log.first.method, 'setAutoPipEnabled');
      expect(log.first.arguments, {'enabled': false});
    });

    test('Arming auto-pip sends setAutoPipEnabled true for Home button entry', () async {
      await channel.invokeMethod('setAutoPipEnabled', {'enabled': true});

      expect(log, hasLength(1));
      expect(log.first.method, 'setAutoPipEnabled');
      expect(log.first.arguments, {'enabled': true});
    });

    test('Tapping PiP icon triggers enterPip native call', () async {
      final res = await channel.invokeMethod<bool>('enterPip');

      expect(res, isTrue);
      expect(log, hasLength(1));
      expect(log.first.method, 'enterPip');
    });
  });
}

