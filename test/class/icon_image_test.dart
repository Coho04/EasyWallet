import 'dart:math' as math;
import 'dart:typed_data';

import 'package:easy_wallet/class/icon_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Something like a photo: smooth gradients with grain on top. PNG handles
/// that badly, which is the case the JPEG fallback exists for.
Uint8List photoLikePng(int width, int height) {
  final random = math.Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    final grain = random.nextInt(24);
    pixel
      ..r = (pixel.x * 255 ~/ width + grain).clamp(0, 255)
      ..g = (pixel.y * 255 ~/ height + grain).clamp(0, 255)
      ..b = ((pixel.x + pixel.y) * 127 ~/ (width + height) + grain).clamp(
        0,
        255,
      );
  }
  return img.encodePng(image);
}

void main() {
  group('downscaleIconImage', () {
    testWidgets('shrinks the longest side to the limit and keeps the ratio', (
      tester,
    ) async {
      final result = await tester.runAsync(
        () => downscaleIconImage(photoLikePng(1200, 600)),
      );

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, iconImageMaxSide);
      expect(decoded.height, iconImageMaxSide ~/ 2);
    });

    testWidgets('a photo ends up a few KB, not tens', (tester) async {
      final result = await tester.runAsync(
        () => downscaleIconImage(photoLikePng(1024, 1024)),
      );

      // Embedded as Base64 in every backup and synced copy.
      expect(result!.sublist(0, 2), [0xFF, 0xD8], reason: 'JPEG');
      expect(result.lengthInBytes, lessThan(10 * 1024));
    });

    testWidgets('a flat graphic stays PNG and keeps its transparency', (
      tester,
    ) async {
      final logo = img.Image(width: 512, height: 512, numChannels: 4);
      img.fillCircle(
        logo,
        x: 256,
        y: 256,
        radius: 200,
        color: img.ColorRgba8(255, 0, 0, 255),
      );

      final result = await tester.runAsync(
        () => downscaleIconImage(img.encodePng(logo)),
      );

      expect(result!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      final decoded = img.decodePng(result)!;
      expect(decoded.width, iconImageMaxSide);
      expect(decoded.getPixel(0, 0).a, 0);
    });

    testWidgets('leaves a small picture at its size', (tester) async {
      final result = await tester.runAsync(
        () => downscaleIconImage(photoLikePng(40, 30)),
      );

      final decoded = img.decodeImage(result!)!;
      expect(decoded.width, 40);
      expect(decoded.height, 30);
    });

    testWidgets('rejects something that is not a picture', (tester) async {
      Object? error;
      await tester.runAsync(() async {
        try {
          await downscaleIconImage(Uint8List.fromList([1, 2, 3, 4]));
        } catch (e) {
          error = e;
        }
      });

      expect(error, isNotNull);
    });
  });
}
