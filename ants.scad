// =========================================================================
// MONOLITHIC THERMAL-OPTIMIZED COPPER ANTHILL CPU WATERBLOCK
// Complete Procedural Script with Cross-Sectional Cutaway and Material HUD
// =========================================================================

// --- USER INTERFACE SWITCHES (Modify these to inspect the design) ---
show_cutaway = false;      // Set to true to slice the block in half and inspect internal tunnels
enable_xray  = true;      // Set to true to make the chassis translucent in preview mode

// --- GLOBAL RENDERING RESOLUTION ---
$fn = 24; // Geometry accuracy (Increase to 45 for production STL manufacturing prints)

// --- PHYSICAL BLOCK DIMENSIONS (mm) ---
block_width  = 50;
block_length = 50;
block_height = 24;

// Fluid Connector Port Positions
inlet_x = -14;
inlet_y = 0;
inlet_z = 9; 

outlet_x = 14;
outlet_y = 0;
outlet_z = 9;


// --- MAIN VISUAL COMPILER ---
if (show_cutaway) {
    // Slices away the front half of the finished block for visualization
    difference() {
        generate_waterblock();
        
        // Cutting plane box
        translate([0, -block_length/2 - 0.1, 0])
            cube([block_width + 10, block_length, block_height + 20], center=true);
    }
} else {
    // Renders the full un-sliced, airtight waterblock manifold
    generate_waterblock();
}


// =========================================================================
// CORE GEOMETRY PIPELINE
// =========================================================================
module generate_waterblock() {
    difference() {
        
        // 1. CHASSIS OUTER MANIFOLD (Solid Copper Extrusion Matrix)
        union() {
            if (enable_xray) {
                // Render with semi-transparent copper styling
                color([0.85, 0.43, 0.28, 0.45]) 
                    cube([block_width, block_length, block_height], center=true);
            } else {
                // Render as raw solid copper
                color([0.85, 0.43, 0.28, 1.0]) 
                    cube([block_width, block_length, block_height], center=true);
            }
            
            // G1/4" Fitting Structural Bosses
            color([0.85, 0.43, 0.28]) {
                translate([inlet_x, inlet_y, (block_height / 2) + 2.5]) 
                    cylinder(h=5, r=7.5, center=true);
                
                translate([outlet_x, outlet_y, (block_height / 2) + 2.5]) 
                    cylinder(h=5, r=7.5, center=true);
            }
        }

        // 2. SUBTRACTIVE INTERNAL ANTHILL FLUID LOOP (Carved Cavities)
        // Highlighting internal fluid geometry in neon blue for clarity
        color([0.1, 0.55, 1.0, 1.0]) union() {
            
            // Distribution and Collection Plenums
            translate([inlet_x, inlet_y, inlet_z - 4]) sphere(r=6.8, $fn=32);
            translate([outlet_x, outlet_y, outlet_z - 4]) sphere(r=6.8, $fn=32);
            
            // Vertical Fluid Feed Channels
            translate([inlet_x, inlet_y, inlet_z - 2]) cylinder(h=22, r=4.0, center=true);
            translate([outlet_x, outlet_y, outlet_z - 2]) cylinder(h=22, r=4.0, center=true);

            // --- TRUNK CHANNEL ARRAY 1 ---
            tunnel_segment([-14.000, 0.000, 4.000, 3.400], [-8.421, -12.180, -2.484, 1.481]);
            tunnel_segment([-8.421, -12.180, -2.484, 1.481], [-2.348, -13.842, -7.112, 1.624]);
            tunnel_segment([-2.348, -13.842, -7.112, 1.624], [3.109, -14.211, -4.954, 1.341]);
            tunnel_segment([3.109, -14.211, -4.954, 1.341], [8.922, -13.114, 1.258, 2.104]);
            tunnel_segment([8.922, -13.114, 1.258, 2.104], [14.000, 0.000, 4.000, 3.400]);

            // --- TRUNK CHANNEL ARRAY 2 ---
            tunnel_segment([-14.000, 0.000, 4.000, 3.400], [-7.910, -5.321, -5.110, 2.210]);
            tunnel_segment([-7.910, -5.321, -5.110, 2.210], [-3.112, -7.844, -7.800, 1.290]);
            tunnel_segment([-3.112, -7.844, -7.800, 1.290], [2.441, -6.112, -3.421, 1.840]);
            tunnel_segment([2.441, -6.112, -3.421, 1.840], [9.112, -4.920, 2.810, 1.350]);
            tunnel_segment([9.112, -4.920, 2.810, 1.350], [14.000, 0.000, 4.000, 3.400]);

            // --- TRUNK CHANNEL ARRAY 3 (Central Flow Core) ---
            tunnel_segment([-14.000, 0.000, 4.000, 3.400], [-9.114, 1.204, -6.211, 1.220]);
            tunnel_segment([-9.114, 1.204, -6.211, 1.220], [-2.911, -0.414, -8.910, 1.780]);
            tunnel_segment([-2.911, -0.414, -8.910, 1.780], [3.241, 1.109, -5.412, 1.310]);
            tunnel_segment([3.241, 1.109, -5.412, 1.310], [8.712, -0.812, 0.412, 2.340]);
            tunnel_segment([8.712, -0.812, 0.412, 2.340], [14.000, 0.000, 4.000, 3.400]);

            // --- TRUNK CHANNEL ARRAY 4 ---
            tunnel_segment([-14.000, 0.000, 4.000, 3.400], [-8.241, 6.421, -4.112, 2.050]);
            tunnel_segment([-8.241, 6.421, -4.112, 2.050], [-3.412, 8.121, -7.210, 1.420]);
            tunnel_segment([-3.412, 8.121, -7.210, 1.420], [2.911, 7.341, -4.112, 1.960]);
            tunnel_segment([2.911, 7.341, -4.112, 1.960], [9.312, 5.811, 1.921, 1.550]);
            tunnel_segment([9.312, 5.811, 1.921, 1.550], [14.000, 0.000, 4.000, 3.400]);

            // --- TRUNK CHANNEL ARRAY 5 ---
            tunnel_segment([-14.000, 0.000, 4.000, 3.400], [-7.822, 13.114, -1.942, 1.520]);
            tunnel_segment([-7.822, 13.114, -1.942, 1.520], [-2.112, 14.821, -6.912, 1.850]);
            tunnel_segment([-2.112, 14.821, -6.912, 1.850], [3.812, 13.412, -5.110, 1.280]);
            tunnel_segment([3.812, 13.412, -5.110, 1.280], [8.441, 12.110, 2.412, 2.150]);
            tunnel_segment([8.441, 12.110, 2.412, 2.150], [14.000, 0.000, 4.000, 3.400]);

            // --- BOUNDARY FLUID MIXING JUXTAPOSITION CROSS-LINKS ---
            tunnel_segment([-2.348, -13.842, -7.112, 1.2], [-3.112, -7.844, -7.800, 1.2]);
            tunnel_segment([3.109, -14.211, -4.954, 1.1], [2.441, -6.112, -3.421, 1.1]);
            tunnel_segment([-2.911, -0.414, -8.910, 1.3], [-3.412, 8.121, -7.210, 1.3]);
            tunnel_segment([2.911, 7.341, -4.112, 1.2], [3.812, 13.412, -5.110, 1.2]);
            tunnel_segment([-3.112, -7.844, -7.800, 1.4], [-2.911, -0.414, -8.910, 1.4]);
            tunnel_segment([2.441, -6.112, -3.421, 1.2], [3.241, 1.109, -5.412, 1.2]);
        }
    }
}

// =========================================================================
// INTERPOLATION INTERFACE ENGINE
// Linearly morphs dynamic paths using point variables: [X, Y, Z, Radius]
// =========================================================================
module tunnel_segment(nodeA, nodeB) {
    hull() {
        translate([nodeA[0], nodeA[1], nodeA[2]]) {
            sphere(r = nodeA[3], $fn = 12);
        }
        translate([nodeB[0], nodeB[1], nodeB[2]]) {
            sphere(r = nodeB[3], $fn = 12);
        }
    }
}