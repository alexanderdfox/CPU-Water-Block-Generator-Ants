// CPU Water Cooling Block with Interconnected Concentric Tori
// Parametric solid model with internal hollowed fluid paths

// Parameters
block_width = 60;       // Outer width of the block (mm)
block_length = 60;      // Outer length
block_height = 25;      // Total height of the block
num_rings = 3;          // Number of concentric tori rings
ring_spacing = 6.5;     // Distance between centers of concentric rings
torus_minor_r = 2.5;    // Radius of the fluid channel tube (thickness of the torus)
innermost_radius = 8;   // Distance from center to the first ring

port_diameter = 10;     // Diameter of inlet/outlet ports
port_height = 8;        // Height of the external port nubs
port_offset = 21;       // Distance from center for ports (aligned with outer torus)

$fn = 60;               // Global fragments for smoothness

// Main construction block
difference() {
    union() {
        // 1. The Main Solid Block Body
        translate([-block_width/2, -block_length/2, 0])
            cube([block_width, block_length, block_height]);
        
        // 2. External Port Nubs (Inlet / Outlet Connectors)
        translate([port_offset, 0, block_height])
            cylinder(h=port_height, d=port_diameter);
        
        translate([-port_offset, 0, block_height])
            cylinder(h=port_height, d=port_diameter);
    }

    // 3. INTERNAL HOLLOW CHANNELS (Subtracted from the solid)
    // All internal fluid paths are grouped here to carve out the solid block
    union() {
        // Torus Center Height: Positioned safely in the middle of the block
        torus_z = block_height / 2;

        // Generate Concentric Hollow Tori
        for (i = [0 : num_rings-1]) {
            major_r = innermost_radius + (i * ring_spacing);
            
            translate([0, 0, torus_z])
                rotate_extrude()
                    translate([major_r, 0, 0])
                        circle(r = torus_minor_r);
        }

        // Interconnecting Manifold Bar (A cylindrical tunnel linking all rings)
        // It runs horizontally along the X-axis through the center of the tori
        translate([-port_offset, 0, torus_z])
            rotate([0, 90, 0])
                cylinder(h = port_offset * 2, r = torus_minor_r);
    }

    // 4. Port Vertical Channels (Feeds fluid from external ports down into the manifold)
    translate([port_offset, 0, block_height / 2])
        cylinder(h = block_height, d = port_diameter - 2);
    
    translate([-port_offset, 0, block_height / 2])
        cylinder(h = block_height, d = port_diameter - 2);

    // 5. Corner Mounting Holes
    mounting_hole( block_width/2 - 5,  block_length/2 - 5);
    mounting_hole(-block_width/2 + 5,  block_length/2 - 5);
    mounting_hole( block_width/2 - 5, -block_length/2 + 5);
    mounting_hole(-block_width/2 + 5, -block_length/2 + 5);
}

// Reusable module for clean mounting screw cutouts
module mounting_hole(x, y) {
    translate([x, y, -1])
        cylinder(h = block_height + 10, d = 4);
}

echo("CPU Water Block with interconnected tori generated successfully. Press F5 to View / F6 to Render.");