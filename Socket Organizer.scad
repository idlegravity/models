// A simple OpenSCAD script to generate a socket holder for a tool chest drawer.

// --- User defined variables ---
// Rows of sockets. A socket is defined by its [diameter, depth, label]
sockets = [
    [ [ 26, 20, "17" ], [ 28, 20, "18" ], [ 28, 20, "19" ], [ 30, 20, "21" ], [ 32, 20, "22" ], [ 38, 20, "27" ] ],
    [ [ 24, 20, "10" ], [ 24, 20, "11" ], [ 24, 20, "12" ], [ 24, 20, "13" ], [ 24, 20, "14" ], [ 24, 20, "15" ], [ 24, 20, "16" ] ]
];

hole_depth = 20;                // Depth of the holes.
clearance = .5;                 // Additional clearance around each socket.
margin = 2;                     // Space between sockets and the edge of the tray.
min_padding = 2;                // Minimum space between each socket. Padding may be increased on some rows to keep spacing even.
min_bottom_thickness = 2;       // Space between the depest socket and the bottom of the tray.
label_text_size = 8;            // Font size for the socket labels.
label_depth = 1;                // Depth of the raised labels. Positive is raised, negative is embossed.
aligned_labels = false;         // If true, labels will be vertically aligned on each row. If false, labels will be offset from the sockets.
// tray_text = "Metric ⅜\" drive"; // TODO: Extra text to be added to the tray. Can be left blank for smaller trays.
// tray_text_size = 10;            // TODO: Font size for the tray text.
tray_width = 0;                 // If the sockets will fit in this width, it will be used. If not, the tray will be as wide as necessary.
                                // It might be fun to do the same thing with the height and depth but I haven't implemented that yet.

// --- Do not edit below this line ---

// Render nice, smooth circles.
$fa = 1;
$fs = 0.1;

// Separate the diameter, depth, and label values into their own arrays for convenience.
diameters = [for (row = sockets) [for (socket = row) socket[0] + clearance]];
depths = [for (row = sockets) [for (socket = row) socket[1]]];
labels = [for (row = sockets) [for (socket = row) socket[2]]];
// echo("diameters", diameters);
// echo("depths", depths);
// echo("labels", labels);

// Calculate the maximum diameter of each row.
max_row_diameters = [for (row = diameters) max(row)];
// echo("max_row_diameters", max_row_diameters);

label_size = label_text_size + min_padding;
// echo(msg = "label_size", label_size);

// Calculate the dimensions of the tray.
tray_x = max(max([for (row = diameters) sumVector(row) + ((len(row) - 1) * min_padding) + (2 * margin)]), tray_width);
tray_y = sumVector(max_row_diameters) + (2 * margin) + (len(sockets) * label_size) + ((len(sockets) - 1) * min_padding);
tray_z = max([for (row = depths) max(row)]) + min_bottom_thickness;
// echo("tray_x", tray_x);
// echo("tray_y", tray_y);
// echo("tray_z", tray_z);

// Calculate the padding for each row.
padding = [for (row = diameters) (tray_x - sumVector(row) - (2 * margin)) / (len(row) - 1)];
// echo("padding", padding);

socket_x_coords = [for (i = [0:len(diameters) - 1]) [for (a = 0, b = (diameters[i][0] / 2) + margin; a < len(diameters[i]); a = a + 1, b = b + ((diameters[i][a - 1] / 2) + (diameters[i][a] == undef ? 0 : (diameters[i][a] / 2))) + padding[i]) b]];
// echo("socket_x_coords", socket_x_coords);

socket_y_coords = [for (i = [0:len(diameters) - 1]) [for (j = [0:len(diameters[i]) - 1]) (i > 0 ? (cumulativeSum(max_row_diameters, i - 1)[i - 1]) : 0) + (max_row_diameters[i] / 2) + margin + (i * min_padding) + ((i + 1) * label_size)]];
// echo("socket_y_coords", socket_y_coords);

// Create the tray and cut out the socket holes.
difference()
{
    cube([ tray_x, tray_y, tray_z ]);
    for (i = [0:len(sockets) - 1])
    {
        for (j = [0:len(sockets[i]) - 1])
        {
            translate([ socket_x_coords[i][j], socket_y_coords[i][j], tray_z - depths[i][j] ]) cylinder(h = depths[i][j], d = diameters[i][j]);
        }
    }
}

// Add labels.
if (aligned_labels)
{
    // Vertically aligned labels.
    for (i = [0:len(sockets) - 1])
    {
        for (j = [0:len(sockets[i]) - 1])
            {
                translate([socket_x_coords[i][j], margin + (i * min_padding) + (i * label_size) + (i > 0 ? (cumulativeSum(max_row_diameters, i - 1)[i - 1]) : 0), tray_z])
                linear_extrude(height = label_depth)
                text(text = labels[i][j], font = "Liberation Sans:style=Bold", size = label_text_size, halign = "center");
            }
    }
}
else
{
    // Labels offset from the sockets.
    for (i = [0:len(sockets) - 1])
    {
        for (j = [0:len(sockets[i]) - 1])
            {
                translate([socket_x_coords[i][j], socket_y_coords[i][j] - (diameters[i][j] / 2) - label_size, tray_z])
                linear_extrude(height = label_depth)
                text(text = labels[i][j], font = "Liberation Sans:style=Bold", size = label_text_size, halign = "center");
            }
    }
}
// Conveneience functions.
// Sum all elements of a vector.
function sumVector(v) = [for (p = v) 1] * v;

// Cumulative sum of a vector up given index.
function cumulativeSum(v, index) = [for (a = v[0] - v[0], i = 0; i <= index; a = a + v[i], i = i + 1) a + v[i]];