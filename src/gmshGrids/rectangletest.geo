// square.geo
// Define the geometry for a square with side length of 1 unit

// Define points
Point(1) = {0, 0, 0, 1.0};  // Bottom-left corner
Point(2) = {4, 0, 0, 1.0};  // Bottom-right corner
Point(3) = {4, 1, 0, 1.0};  // Top-right corner
Point(4) = {0, 1, 0, 1.0};  // Top-left corner

// Define lines
Line(1) = {1, 2};  // Bottom edge
Line(2) = {2, 3};  // Right edge
Line(3) = {3, 4};  // Top edge
Line(4) = {4, 1};  // Left edge

// Define line loop and plane surface
Line Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// Mesh options
Mesh.Algorithm = 5;  // 2D mesh algorithm (default is 6)
Mesh.ElementOrder = 1;  // Linear elements

// Define the mesh size near the points (optional)
Field[1] = MathEval;
Field[1].F = "0.1";  // Mesh size
Background Field = 1;

//+
Extrude {0, 0, 3} {
  Surface{1}; 
}
