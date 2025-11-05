import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:ironcirclesapp/screens/stablediffusion/mask/structs/rect_bounds.dart';

class ImageUtils{

  static img.Image additiveBlend(img.Image baseImage, img.Image overlayImage) {
    // Ensure the images are the same size
    assert(baseImage.width == overlayImage.width && baseImage.height == overlayImage.height);

    return img.compositeImage(baseImage, overlayImage,blend: img.BlendMode.addition);

  }

  static RectangleBounds getRectangleEnvelope(List<Offset> screenPoints){

    // Initialize min and max values with the first point
    double minX = screenPoints.first.dx;
    double maxX = screenPoints.first.dx;
    double minY = screenPoints.first.dy;
    double maxY = screenPoints.first.dy;

    // Iterate over the swipe points to find the boundaries
    for (Offset point in screenPoints) {
      minX = min(minX, point.dx);
      maxX = max(maxX, point.dx);
      minY = min(minY, point.dy);
      maxY = max(maxY, point.dy);
    }
    return RectangleBounds(maxX: maxX, maxY: maxY, minX: minX, minY: minY);

  }
  static int countWhitePixels(img.Image image) {
    int whitePixelCount = 0;

    // The image length gives the total number of pixels in the image
    for (final pixel in image) {

      // Extract RGBA components from the pixel value
      int r = pixel.r.toInt();
      int g = pixel.g.toInt();
      int b = pixel.b.toInt();
      int a = pixel.a.toInt();

      // Check if the pixel is white and fully opaque
      if (r == 255 && g == 255 && b == 255 && a == 255) {
        whitePixelCount++;
      }
    }

    return whitePixelCount;
  }
  /// Retrieves the dimensions of an image from its byte data.
  /// This function decodes the image bytes to obtain a [ui.Image] object, from which the dimensions of the image are extracted. It's particularly useful for getting the size of an image without fully rendering it in the widget tree, which can be advantageous for layout calculations or when manipulating the image data directly.
  /// [imageBytes]: The byte array of the image for which dimensions are to be determined.
  /// Returns a [Future<ui.Size>] that resolves to the size of the image, encapsulating its width and height in pixels.
  /// Throws an exception if the image cannot be decoded or if there are issues obtaining the frame information.
  static Future<ui.Size> getImageDimensions(Uint8List imageBytes) async {
    // Decode the image from the bytes
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    // Get the first frame of the image
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    // Get the image from the frame
    final ui.Image image = frameInfo.image;
    // Return the dimensions of the image
    return ui.Size(image.width.toDouble(), image.height.toDouble());
  }

  static Future<ui.Image> getImageFromBytes(Uint8List imageBytes) async {
    // Decode the image from the bytes
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    // Get the first frame of the image
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    // Get the image from the frame
    final ui.Image image = frameInfo.image;
    // Return the dimensions of the image
    return image;
  }
}