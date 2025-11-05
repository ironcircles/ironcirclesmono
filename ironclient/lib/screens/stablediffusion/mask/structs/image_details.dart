import 'package:flutter/material.dart';

/// Represents the metadata of an image with utilities to determine its orientation and scaling.
///
/// This class encapsulates essential properties of an image such as its URL, width, and height,
/// and provides methods to assess and manipulate image dimensions relative to certain criteria.
///
/// Attributes:
///   url (String): The URL source of the image.
///   width (int): The width of the image in pixels.
///   height (int): The height of the image in pixels.
///
/// Methods:
///   isLandscape(): Returns `true` if the image is wider than it is tall.
///   isPortrait(): Returns `true` if the image is taller than it is wide.
///   getAspectRatio(): Calculates the aspect ratio of the image as width divided by height.
///
///   getWidthInSquareContainer(double containerSize):
///     Calculates and returns the dimensions of the image when it needs to be fitted within
///     a square container. The result is provided as an `Offset` where:
///     - x represents the width the image should take within the container,
///     - y represents the height the image should take within the container.
///     This method ensures that the image maintains its aspect ratio within the square container,
///     adjusting its dimensions appropriately based on its orientation (landscape or portrait).
///
/// Example Usage:
///   ImageDetails details = ImageDetails('http://example.com/image.jpg', 640, 480);
///   bool landscape = details.isLandscape(); // true
///   double aspectRatio = details.getAspectRatio(); // 1.333
///   Offset fittedDimensions = details.getWidthInSquareContainer(300); // Offset(300, 225)
class ImageDetails{
  final String url;
  final int width;
  final int height;
  final file;
  const ImageDetails(this.url,this.width,this.height, this.file);


  bool isLandscape(){
    return width>height;
  }
  bool isPortrait(){
    return width<height;
  }
  double getAspectRatio(){
    return width/height;
  }
  Offset getWidthInSquareContainer(double containerSize){


    if (width==height) return Offset(containerSize,containerSize);
    if(isLandscape())
      return Offset(containerSize,containerSize/getAspectRatio()  );;
//if(isPortrait())
    return Offset(containerSize*getAspectRatio(),containerSize);;

  }
}