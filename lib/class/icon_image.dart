import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Longest side of a picture used as a subscription icon, in pixels. Enough
/// for the largest place an icon is drawn at three times the pixel density,
/// small enough to embed in every backup and synced copy.
const int iconImageMaxSide = 128;

/// Above this a PNG is re-encoded as JPEG. Logos and flat graphics stay PNG
/// and keep their transparency; photos would otherwise cost tens of KB each.
const int iconImagePngBudget = 12 * 1024;

/// Shrinks a picked picture to [maxSide] and encodes it compactly.
///
/// Decoded by the engine rather than in Dart, so everything the platform can
/// open works, HEIC from an iPhone library included. Throws when [source] is
/// not an image.
Future<Uint8List> downscaleIconImage(
  Uint8List source, {
  int maxSide = iconImageMaxSide,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(source);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final codec = await _codecFor(descriptor, maxSide);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) {
      throw StateError('The picture could not be encoded');
    }
    if (png.lengthInBytes <= iconImagePngBudget) {
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    }
    return await _encodeJpeg(image);
  } finally {
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}

Future<ui.Codec> _codecFor(ui.ImageDescriptor descriptor, int maxSide) {
  final longest = math.max(descriptor.width, descriptor.height);
  if (longest <= maxSide) {
    return descriptor.instantiateCodec();
  }
  final scale = maxSide / longest;
  return descriptor.instantiateCodec(
    targetWidth: math.max(1, (descriptor.width * scale).round()),
    targetHeight: math.max(1, (descriptor.height * scale).round()),
  );
}

/// JPEG has no alpha channel, so transparent parts are laid onto white
/// instead of turning black.
Future<Uint8List> _encodeJpeg(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    throw StateError('The picture could not be encoded');
  }
  // rawRgba is premultiplied, so blending onto white is adding what the
  // alpha leaves uncovered.
  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final rgb = Uint8List(image.width * image.height * 3);
  for (var src = 0, dst = 0; src < rgba.length; src += 4, dst += 3) {
    final uncovered = 255 - rgba[src + 3];
    rgb[dst] = math.min(255, rgba[src] + uncovered);
    rgb[dst + 1] = math.min(255, rgba[src + 1] + uncovered);
    rgb[dst + 2] = math.min(255, rgba[src + 2] + uncovered);
  }
  final opaque = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
  return img.encodeJpg(opaque, quality: 80);
}
