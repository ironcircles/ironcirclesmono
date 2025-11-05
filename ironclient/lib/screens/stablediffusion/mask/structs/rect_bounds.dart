/// A utility class for defining the bounds of a rectangle.
///
/// This class is used to represent a rectangular boundary using the maximum and
/// minimum X and Y coordinates. It provides a structured way to handle
/// rectangular areas, which can be useful in various applications like graphical
/// interfaces, gaming zones, or spatial data analysis.
///
/// Attributes:
///   maxX (double): The maximum X coordinate of the rectangle.
///   maxY (double): The maximum Y coordinate of the rectangle.
///   minX (double): The minimum X coordinate of the rectangle.
///   minY (double): The minimum Y coordinate of the rectangle.
///
/// The class includes:
/// - A constructor for initializing the rectangle with specific boundary values.
/// - A method `containsPoint` to determine whether a given point (x, y) lies
///   within the bounds of the rectangle.
///
/// Example:
/// var bounds = RectangleBounds(maxX: 10, maxY: 10, minX: 0, minY: 0);
/// bool isInside = bounds.containsPoint(5, 5); // returns true
class RectangleBounds {
  double maxX;
  double maxY;
  double minX;
  double minY;

  RectangleBounds({
    required this.maxX,
    required this.maxY,
    required this.minX,
    required this.minY,
  });

  bool containsPoint(int x, int y) {
    return x >= minX && x <= maxX && y >= minY && y <= maxY;
  }
}