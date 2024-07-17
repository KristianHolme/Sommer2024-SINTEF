// Define the parameters of the cuboid
length = 8400; // Length in x-direction
width = 5000; // Width in y-direction
height = 1200; // Height in z-direction
meshSize = 200; //300 for regular, 200 for -M

// Define the points
Point(1) = {0, 0, 0, meshSize};
Point(2) = {length, 0, 0, meshSize};
Point(3) = {length, width, 0, meshSize};
Point(4) = {0, width, 0, meshSize};
Point(5) = {0, 0, height, meshSize};
Point(6) = {length, 0, height, meshSize};
Point(7) = {length, width, height, meshSize};
Point(8) = {0, width, height, meshSize};

// Define the lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};
Line(5) = {1, 5};
Line(6) = {2, 6};
Line(7) = {3, 7};
Line(8) = {4, 8};
Line(9) = {5, 6};
Line(10) = {6, 7};
Line(11) = {7, 8};
Line(12) = {8, 5};

// Define the line loops and surfaces
Line Loop(13) = {1, 2, 3, 4};
Line Loop(14) = {5, 9, -6, -1};
Line Loop(15) = {6, 10, -7, -2};
Line Loop(16) = {7, 11, -8, -3};
Line Loop(17) = {8, 12, -5, -4};
Line Loop(18) = {9, 10, 11, 12};

Plane Surface(19) = {13};
Plane Surface(20) = {14};
Plane Surface(21) = {15};
Plane Surface(22) = {16};
Plane Surface(23) = {17};
Plane Surface(24) = {18};

// Define the volume
Surface Loop(25) = {19, 20, 21, 22, 23, 24};
Volume(26) = {25};

// Mesh options
Mesh.Algorithm = 5;  // 2D mesh algorithm (default is 6)
Mesh.Algorithm3D = 1;
Mesh.ElementOrder = 1;  // Linear elements
