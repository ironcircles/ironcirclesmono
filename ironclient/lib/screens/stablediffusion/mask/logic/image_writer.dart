import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:ironcirclesapp/blocs/log_bloc.dart';
import 'package:ironcirclesapp/models/globalstate.dart';
import 'package:path/path.dart' as p;

class ImageWriter {
  /// Saves an [img.Image] object to the application's documents directory as a file.
  /// This function encodes an image object into JPEG format and writes the resulting byte array to a file within the app's documents directory, effectively saving the image locally on the device. The path to the saved image file is then returned.
  /// [image]: The [img.Image] object to be saved.
  /// [filename]: The name of the file to save the image as, including the file extension (e.g., 'image.jpg').
  /// Returns a [Future<String>] that resolves to the path of the saved image file.
  /// Throws an exception if there is an error during the file-saving process.
  static Future<String> saveImageToAppDirectory(
      img.Image image, String filename) async {
    try {
      // Get the directory to save the image
      final maskImagePath = p.join(await globalState.getAppPath(),filename);

      // Encode the image to JPEG format (you can change it to PNG if you prefer)
      final imageBytes = img.encodeJpg(image);

      // Write the image bytes to a file
      File file = File(maskImagePath);
      await file.writeAsBytes(imageBytes);

      //print("Saved to" + maskImagePath);
      return maskImagePath; // Return the path where the image was saved
    } catch (e) {
      debugPrint("Error saving image: $e");
      throw Exception("Failed to save image");
    }
  }

  /// Saves image data from a [Uint8List] to the application's documents directory as a file.
  /// This function writes the given image bytes directly to a file within the app's documents directory, offering a way to persist image data retrieved or generated at runtime (e.g., downloaded images, screenshots). The path to the saved image file is provided upon successful completion.
  /// [imageBytes]: The byte array of the image to be saved.
  /// [filename]: The name of the file to save the image as, which should include the file extension (e.g., 'picture.png').
  /// Returns a [Future<String>] that resolves to the path of the saved image file.
  /// Throws an exception if there is an error saving the image to the file system.
  static Future<String> saveImageBytesToAppDirectory(
      Uint8List imageBytes, String filename) async {
    try {
      // Get the directory to save the image
      final maskImagePath =
          p.join(await globalState.getAppPath(), 'temp_images', filename);

      // Write the image bytes to a file
      File file = File(maskImagePath);
      await file.writeAsBytes(imageBytes);

      //print("Saved to" + maskImagePath);
      return maskImagePath; // Return the path where the image was saved
    } catch (e, trace) {
      LogBloc.insertError(e, trace);
      //print("Error saving image: $e");
      throw Exception("Failed to save image");
    }
  }

  static Future<File?> saveImageAsPngFromUrl(
      String imageUrl, String filename) async {
    try {
      // Fetch the image from the network
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Decode the image to a Dart 'Image' object
        final img.Image? image = img.decodeImage(response.bodyBytes);
        if (image != null) {
          // Encode the 'Image' object to PNG format
          final Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

          // Create a file path using the directory path and filename
          final String filePath = p.join(await globalState.getAppPath(), filename);

          // Create a file at the path
          final File file = File(filePath);

          // Write the PNG data to the file
          await file.writeAsBytes(pngBytes);
          //print("Saved from url to" + filePath);
          return file;
        }
      }
    } catch (e) {
      // Handle errors
      debugPrint('Error saving image: $e');
    }
    return null;
  }

  static Future<File?> saveImageFromUrl(
      String imageUrl, String filename) async {
    try {
      // Fetch the image from the network
      final http.Response response = await http.get(Uri.parse(imageUrl));

      // Get bytes from the network response
      final Uint8List imageData = response.bodyBytes;

      // Create a file path using the directory path and filename
      final String filePath = p.join(await globalState.getAppPath(), filename);

      // Create a file at the path
      final File file = File(filePath);

      // Write the image data to the file
      await file.writeAsBytes(imageData);

      return file;
    } catch (e) {
      // Handle errors (e.g., network error, write error)
      debugPrint('Error saving image: $e');
      return null;
    }
  }
}
