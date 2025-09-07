// euroscad

// -- eurorack case template
// -- with parametrizable size
// -- made in openscad
// -- for 3d printing
// -- github.com/merumerutho


module prism(l, w, h) {
    polyhedron(points=[[0,0,0], [0,w,h], [l,w,h], [l,0,0], [0,w,0], [l,w,0]],
               // top sloping face (A)
               faces=[[0,1,2,3],
               // vertical rectangular face (B)
               [2,1,4,5],
               // bottom face (C)
               [0,3,5,4],
               // rear triangular face (D)
               [0,4,1],
               // front triangular face (E)
               [3,2,5]]
               );}
               
               
/* [Main Parameters] */
hp_width = 84; // HP
extra_width = 0; // mm
internal_depth = 50.; // mm
wall_thickness = 2.6; // mm
base_thickness = 3; // mm
include_case = false;
include_rail = true;
include_handle = true;
remove_bottom = false;
only_bottom = true;
only_rail = true;
half = true;

// Rail
rail_hole_diameter = 3.2; // mm, for M3-clearance
rail_margin_depth = 4; // mm
rail_margin_extra = 2.; // mm
rail_hole_depth = rail_margin_depth;
rail_offset = base_thickness + 4.;      
margin_height = rail_offset - 2. +rail_hole_diameter;
mounting_edge_depth = 15.0; // mm

// Handle
handle_width = 80; // mm
handle_height = 25; // mm
handle_thickness = 12; // mm

/* [Advanced Settings] */
corner_radius = 4; // mm


/* [Hidden] */
$fa = 1;
$fs = 0.4;

// Eurorack standard dimensions
HP_TO_MM = 5.08;                  // Conversion factor: 1HP = 5.08mm
RACK_HEIGHT_3U = 133.35;          // 3U rack height
INTERNAL_HEIGHT = 128.5;          // Internal clearance height
RAIL_SPACING = 122.5;             // Center-to-center rail spacing


function get_wall_thickness() = 
    wall_thickness;

function get_base_thickness() = 
    base_thickness;

// Calculate case dimensions
case_width = hp_width * HP_TO_MM + 2 * (wall_thickness + extra_width);
case_height = RACK_HEIGHT_3U;
case_depth = internal_depth + base_thickness;
wall_thick = wall_thickness;
base_thick = base_thickness;


// Main case assembly
module eurorack_case() {    
    difference(){
        union(){
            difference(){
                union() 
                {
                    if (include_case)
                    {
                        difference() {
                            // Main case body
                            case_body();
                                
                            // Internal cavity
                            case_cavity();
                            
                            // Bottom removal
                            if (remove_bottom){
                                bottom_removal();
                            }
                        }
                    }
                    
                    // Rail margins
                    if (include_rail) {
                        rail_margins();
                    }
                    
                    // Handle on top
                    if (include_handle) {
                        translate([0,case_height,case_depth])
                        rotate([-90,0,0])
                        case_handle();
                    }
                    
                    if(half)
                    {
                        half_support();
                    }
                }
                
                // Subtract holes
                if (include_rail) {
                    rail_holes();
                }
                
                // Keep only bottom
                if (only_bottom) {
                    keep_only_bottom();
                }
                
                // Keep only rail
                if (only_rail) {
                    keep_only_rail();
                }
                
            }
            if (!include_case)
            {
                rail_mounting_edges();
            }
        }
        if (half)
        {
            halven();
        }
    }
}

module keep_only_rail()
{
    union(){
    keep_only_bottom();
    removal_margin = 15.;
    cube([case_width, case_height, case_depth - removal_margin]);
    translate([0,0,0])
    cube([case_width, wall_thickness, case_depth]);
    
    }
}

module keep_only_bottom()
{
    union(){
    translate([0,rail_offset - 1. + margin_height/3+rail_margin_extra,0])
    cube([case_width*2,case_height*2,case_depth*2]);
    /*
    removal_margin = 6.;
    translate([wall_thickness + removal_margin,0, wall_thickness + removal_margin])
    
    cube([case_width - 2*wall_thickness - 2*removal_margin, base_thickness*2, case_depth - 2*wall_thickness - 2*removal_margin]);*/
    }
    
}

module bottom_removal()
{
    removal_margin = 10; // mm
    translate([wall_thickness+removal_margin, wall_thickness+removal_margin,0])
    
    cube([case_width-2*wall_thickness-2*removal_margin, case_height - 2*wall_thickness - 2*removal_margin, base_thickness]);
}

// Case body with rounded corners
module case_body() {
    hull() {
        for (x = [corner_radius, case_width - corner_radius]) {
            for (y = [corner_radius, case_height - corner_radius]) {
                translate([x, y, 0])
                    cylinder(r = corner_radius, h = case_depth);
            }
        }
    }
}

// Internal cavity
module case_cavity() {
    translate([wall_thick, wall_thick, base_thick]) {
        cube([
            case_width - 2 * wall_thick,
            case_height - 2 * wall_thick,
            internal_depth + 1  // +1 to ensure clean boolean
        ]);
    }
}

// Rail margins - solid parallelepipeds for mounting holes
module rail_margins() {
    // Calculate margin dimensions
    margin_width = hp_width * HP_TO_MM + 2*(extra_width);
    
    // Top rail margin
    translate([
        wall_thickness,
        case_height - rail_offset +1. - margin_height/3 - rail_margin_extra,
        case_depth - rail_margin_depth
    ]) {
        cube([margin_width, margin_height+rail_margin_extra, rail_margin_depth]);
    }
    
    // Bottom rail margin  
    translate([
        wall_thickness,
        rail_offset - 1. - 2*margin_height/3,
        case_depth - rail_margin_depth
    ]) {
        cube([margin_width, margin_height+rail_margin_extra, rail_margin_depth]);
    }
}

// Handle - rectangular ergonomic handle on top face
module case_handle() {
    
        // Calculate handle position (centered on top face)
        handle_center_x = case_width / 2;
        handle_center_y = case_depth / 2;
        
        // Handle dimensions
        base_width = handle_width + 2 * handle_thickness/2;
        base_depth = handle_thickness;
        
        translate([handle_center_x - base_width/2, handle_center_y - base_depth/2, 0]) {

                union() {
                    // Left mounting post
                    cube([handle_thickness/2, base_depth, handle_height-handle_thickness/2]);
                    difference(){
                    rotate([0,0,-90])
                    translate([-base_depth,-handle_height,0])
                    prism(base_depth, handle_height, handle_height/2);
                    
                    rotate([0,0,-90])
                    translate([-base_depth+2,-handle_height-1,2])
                    prism(base_depth-4, handle_height-3, handle_height/2);
                    
                    }
                    
                    // Right mounting post  
                    translate([base_width - handle_thickness/2, 0, 0]) {
                        cube([handle_thickness/2, base_depth, handle_height-handle_thickness/2]);
                    }
                    
                    difference(){
                    rotate([0,0,90])
                    translate([0,-handle_width-handle_height-handle_thickness,0])
                    prism(base_depth, handle_height, handle_height/2);
                    
                    rotate([0,0,90])
                    translate([2,-handle_width-handle_height-handle_thickness-1,2])
                    prism(base_depth-4, handle_height-3, handle_height/2);
                    }
                    
                    // Top grip bar (rectangular with rounded edges)
                    translate([handle_thickness/2-handle_thickness/2, handle_thickness/2 , handle_height - handle_thickness/2]) rotate([0,90,0]) {
                        hull() {
                            // Rounded corners for ergonomics
                           
                                        cylinder(d = handle_thickness, h = handle_width + handle_thickness);
                                    
                    } 
                }
            }
        }
    
}

// Rail mounting holes - on the front face (top surface when printed face-down)
module rail_holes() {
    // Calculate number of holes (one per HP plus end holes)
    num_holes = hp_width;
    
    // Top rail holes - on the front face at the top edge
    for (i = [0 : num_holes - 1]) {
        translate([
            wall_thick + extra_width + rail_hole_diameter/2 + i * HP_TO_MM,
            case_height - rail_offset,
            case_depth - rail_hole_depth
        ]) {
            cylinder(d = rail_hole_diameter, h = rail_hole_depth + 1);
        }
    }
    
    // Bottom rail holes - on the front face at the bottom edge  
    for (i = [0 : num_holes - 1]) {
        translate([
            wall_thick + extra_width + rail_hole_diameter/2 + i * HP_TO_MM,
            + rail_offset,
            case_depth - rail_hole_depth
        ]) {
            cylinder(d = rail_hole_diameter, h = rail_hole_depth + 1);
        }
    }
}



module rail_mounting_edges() 
{
    support_width=8.5;
difference(){
    union(){
        translate([0,rail_offset - 1. - 2*margin_height/3, case_depth - rail_margin_depth - mounting_edge_depth])
        cube([wall_thickness,margin_height+rail_margin_extra,rail_margin_depth + mounting_edge_depth]);
        
        translate([0,rail_offset - 1. - 2*margin_height/3, case_depth - rail_margin_depth - mounting_edge_depth])
        cube([support_width, margin_height+rail_margin_extra, mounting_edge_depth]);
        
        translate([case_width - wall_thick, rail_offset - 1. - 2*margin_height/3, case_depth - rail_margin_depth - mounting_edge_depth])
        cube([wall_thickness,margin_height+rail_margin_extra,rail_margin_depth + mounting_edge_depth]);
        
        translate([case_width - support_width, rail_offset - 1. - 2*margin_height/3, case_depth - rail_margin_depth - mounting_edge_depth])
        cube([support_width, margin_height+rail_margin_extra, mounting_edge_depth]);
    }
    translate([0,0,0])
    cube([case_width, wall_thickness, case_depth]);
    }
}


module halven()
{
    translate([case_width/2-(HP_TO_MM-rail_hole_diameter)/2,0,0])
    cube([case_width, case_height*2, case_depth]);
}

module half_support()
{
    support_width=8.5;
    support_depth=8.;
    translate([case_width/2-support_width, rail_offset - 1. - 2*margin_height/3,
        case_depth - rail_margin_depth -support_depth])
    cube([support_width, margin_height+rail_margin_extra, support_depth]);
}

// Main output
eurorack_case();