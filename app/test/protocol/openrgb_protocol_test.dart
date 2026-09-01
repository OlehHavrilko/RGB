import 'dart:typed_data';

import 'package:chromify/protocol/openrgb_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenRgbProtocol.header', () {
    test('магия + little-endian поля, 16 байт', () {
      final bytes = OpenRgbProtocol.header(
        deviceId: 1,
        packetId: OpenRgbProtocol.packetIdUpdateLeds,
        dataSize: 0x0100,
      );
      expect(bytes.length, OpenRgbProtocol.headerSize);
      expect(bytes.sublist(0, 4), [0x4F, 0x52, 0x47, 0x42]); // "ORGB"
      expect(bytes.sublist(4, 8), [1, 0, 0, 0]);
      expect(
        bytes.sublist(8, 12),
        [OpenRgbProtocol.packetIdUpdateLeds & 0xFF, 0x04, 0, 0],
      );
      expect(bytes.sublist(12, 16), [0x00, 0x01, 0x00, 0x00]);
    });

    test('decodeHeader — round trip с header()', () {
      final bytes = OpenRgbProtocol.header(
        deviceId: 3,
        packetId: OpenRgbProtocol.packetIdRequestControllerCount,
        dataSize: 42,
      );
      final decoded = OpenRgbProtocol.decodeHeader(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.deviceId, 3);
      expect(decoded.packetId, OpenRgbProtocol.packetIdRequestControllerCount);
      expect(decoded.dataSize, 42);
    });

    test('decodeHeader — null при неверной магии или коротком буфере', () {
      final good = OpenRgbProtocol.header(deviceId: 0, packetId: 0, dataSize: 0);
      final corrupted = Uint8List.fromList(good)..[0] = 0x00;
      expect(OpenRgbProtocol.decodeHeader(corrupted), isNull);
      expect(OpenRgbProtocol.decodeHeader(Uint8List(8)), isNull);
    });
  });

  group('OpenRgbProtocol.clientNamePayload', () {
    test('имя клиента как C-строка с нулевым байтом на конце', () {
      final bytes = OpenRgbProtocol.clientNamePayload('Chromify');
      expect(bytes.length, 'Chromify'.length + 1);
      expect(bytes.last, 0);
      expect(String.fromCharCodes(bytes.sublist(0, 8)), 'Chromify');
    });
  });

  group('protocol version', () {
    test('запрос кодирует версию как u32 little-endian', () {
      final bytes = OpenRgbProtocol.protocolVersionRequestPayload(6);
      expect(bytes, [6, 0, 0, 0]);
    });

    test('decodeProtocolVersion читает u32 little-endian', () {
      expect(
        OpenRgbProtocol.decodeProtocolVersion(Uint8List.fromList([6, 0, 0, 0])),
        6,
      );
      expect(OpenRgbProtocol.decodeProtocolVersion(Uint8List(2)), isNull);
    });
  });

  group('decodeControllerCount', () {
    test('читает u32 little-endian', () {
      expect(
        OpenRgbProtocol.decodeControllerCount(
          Uint8List.fromList([3, 0, 0, 0]),
        ),
        3,
      );
      expect(OpenRgbProtocol.decodeControllerCount(Uint8List(0)), isNull);
    });
  });

  group('OpenRgbProtocol.updateLedsPayload', () {
    test('пустой список: data_size(4) + count(2) = 6, count=0', () {
      final bytes = OpenRgbProtocol.updateLedsPayload(const []);
      expect(bytes.length, 6);
      expect(bytes.sublist(0, 4), [6, 0, 0, 0]);
      expect(bytes.sublist(4, 6), [0, 0]);
    });

    test('два цвета: data_size = 4+2+4*2 = 14, RGBColor = R G B 00', () {
      final bytes = OpenRgbProtocol.updateLedsPayload(const [
        (0x11, 0x22, 0x33),
        (0xFF, 0x00, 0x80),
      ]);
      expect(bytes.length, 14);
      expect(bytes.sublist(0, 4), [14, 0, 0, 0]);
      expect(bytes.sublist(4, 6), [2, 0]);
      expect(bytes.sublist(6, 10), [0x11, 0x22, 0x33, 0x00]);
      expect(bytes.sublist(10, 14), [0xFF, 0x00, 0x80, 0x00]);
    });

    test('каналы за пределами байта отбрасываются маской 0xFF', () {
      final bytes = OpenRgbProtocol.updateLedsPayload(const [(300, -1, 256)]);
      expect(bytes.sublist(6, 10), [300 & 0xFF, (-1) & 0xFF, 256 & 0xFF, 0x00]);
    });
  });
}
