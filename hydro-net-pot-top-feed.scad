inputs = 1;
input_size = 4.9;
output_size = 4.9;
input_strength = 1.2;
input_barb_count = 3;
outputs = 1;
output_strength = 1.2;
output_smooth_length = 2.0;
output_barb_count = 3;
connector_type = "vault"; // [inline,vault]
inline_junction_type = "round"; // [round,hex,none]
vault_wall_thickness = 1.5;
vault_support = "no"; // [yes,no]
vault_connector_ratio = 1.8;
inline_junction_width = 0.8;
output_inside_diameter_ratio = 0.6;
input_inside_diameter_ratio = 0.6;


union()
{
    translate([40,-24,-25]) rotate([0,0,-30]) make_adapter( input_size, output_size );
    translate([53,-15,17]) rotate([0,180,0]) make_adapter( input_size, output_size, false );
    //translate([5,-8,-15]) rotate([40,90,0]) make_adapter( input_size, output_size, false );
    pot();
}


module pot()
{
      translate([0,0,8.5]) scale([4.7,4.7,12]) difference() {
        sphere(10);
        sphere(9.7);
        N=250; // number of points to distribue
        // height angle (given as multiple of PI) until which to distribute holes.
        max_height_angle = 1.04;
        for(i=[0:N]) {
          radius = 10 - 2;
          theta = 360*i / 1.618;  // (0..N*360°) / 1.618
          phi = acos(1 - max_height_angle*i/N);
          // translate (theta, phi, r) to cartesian coords
          xi = cos(theta)*sin(phi) * radius;
          yi = sin(theta)*sin(phi) * radius;
          zi = cos(phi) * radius;
          translate([xi,yi,zi]) rotate([0,phi,theta]) cylinder(h=2, r=.7, $fn=6);
        }
        translate([0,0,-18]) cylinder(16,10,10);
        
        
      }
      

    
      translate([0,0,-20])
            rotate_extrude(angle=290, convexity = 10, $fn = 100)
                translate([49, 0, 0])
                    difference()
                    {
                        square(10, center = true);
                        circle(3);
                    };

      translate([11,-32.1,-20]) rotate([0, 0,-70]) 
            rotate_extrude(angle=120, convexity = 10, $fn = 100)
                translate([15, 0, 0]) 
                    difference()
                    {
                        square(10, center = true);
                        circle(3);
                    };

      translate([49,0,-5]) rotate([180, 90, 0]) 
            rotate_extrude(angle=90, convexity = 10, $fn = 100)
                translate([15, 0, 0]) 
                    difference()
                    {
                        square(10, center = true);
                        circle(3);
                    };
}


module make_adapter( input_diameter, output_diameter, bothsides=true )
{

if (connector_type == "inline" && inputs == 1 && outputs == 1)
{
  union() {
      junction_height = 4;
          input_barb( input_diameter );
          junction( input_diameter, output_diameter, junction_height );
      output_barb( input_diameter, output_diameter, junction_height );
  }
}
if (connector_type == "vault" || inputs > 1 || outputs > 1)
{
  center_width = max(inputs * input_diameter * vault_connector_ratio, outputs * output_diameter * vault_connector_ratio);
  center_height = max(input_diameter * vault_connector_ratio, output_diameter * vault_connector_ratio);
  // Should be 4 normally
  junction_height = 4;
  center_empty_input = center_width - input_diameter * vault_connector_ratio * inputs;
  center_empty_output = center_width - output_diameter * vault_connector_ratio * outputs;
  // New to 1.5: for vault, use reinforcing ring to reduce snap-off tendency
  // Reinforcement units are fractions of inside diameter
  union() {
       //input_barb( input_diameter );
       for (i = [1:inputs]) 
	    {
		   translate( [center_empty_input / 2 + input_diameter * vault_connector_ratio / 2 + input_diameter * (i-1) * vault_connector_ratio,0,0] ) input_barb( input_diameter, 0.4 );
	    }

		 difference()
		 {
			translate([-vault_wall_thickness,-vault_wall_thickness,0]) vault( input_diameter, junction_height, center_width, center_height, center_height, vault_wall_thickness, output_diameter, center_empty_output );
			for (i = [1:inputs]) 
			{
				// Make holes in the vault for input entry
      		translate( [center_empty_input / 2 + input_diameter * vault_connector_ratio / 2 + input_diameter * (i-1) * vault_connector_ratio,0,input_diameter * input_barb_count * 0.9 - center_height / 3] ) cylinder( r=input_diameter * input_inside_diameter_ratio / 2, h=center_height, $fn=60 );
			}
			for (i = [1:outputs]) 
			{
				// Make holes in the vault for output egress
      		translate( [center_empty_output / 2 + output_diameter * vault_connector_ratio / 2 + output_diameter * (i-1) * vault_connector_ratio,0, center_height * 1.5] ) cylinder( r=output_diameter * output_inside_diameter_ratio / 2, h=center_height * 1.9, $fn=60 );
			}
		 } // end vault with holes
       //output_barb( input_diameter, output_diameter, 12 );
         if(bothsides) 
         {
            for (i = [1:outputs]) 
            {
                translate( [center_empty_output / 2 + output_diameter * vault_connector_ratio / 2 + output_diameter * (i-1) * vault_connector_ratio,0,-output_diameter * output_inside_diameter_ratio / 2] ) output_barb( input_diameter, output_diameter, center_height + 2 * vault_wall_thickness, 0.4 );
            }
        }
     }
 } // end if vault
} // end module make_adapter

/****
module tometric( unit_type, value )
{
  if (unit_type == "US") value * 25.4;
  else value;
}
***/

module barbnotch( inside_diameter )
{
  // Generate a single barb notch
  cylinder( h = inside_diameter * 1.0, r1 = inside_diameter * 0.85 / 2, r2 = inside_diameter * 1.16 / 2, $fa = 0.5, $fs = 0.5, $fn = 60 );
}

module solidbarbstack( inside_diameter, count, reinforcement = 0 )
{
    // Generate a stack of barbs for specified count
    // The height of each barb is [inside_diameter]
    // and the total height of the stack is
    // (count - 1) * (inside_diameter * 0.9) + inside_diameter
    union() {
      barbnotch( inside_diameter );
		for (i=[2:count]) 
		{
			translate([0,0,(i-1) * inside_diameter * 0.9]) barbnotch( inside_diameter );
		}
		/***
		if (count > 1) translate([0,0,1 * inside_diameter * 0.9]) barbnotch( inside_diameter );
		if (count > 2) translate([0,0,2 * inside_diameter * 0.9]) barbnotch( inside_diameter );
		***/
        if (reinforcement > 0) translate([0,0,(count-1)*inside_diameter * 0.9 + inside_diameter * 0.5]) cylinder( h = inside_diameter * 0.5, r1 = inside_diameter * 0.85 / 2, r2 = inside_diameter * (1.16 + reinforcement) / 2, $fa = 0.5, $fs = 0.5, $fn = 60 );
    }
}

module barb( inside_diameter, count, strength_factor, reinforcement = 0 )
{
  // Generate specified number of barbs
  // with a single hollow center removal
  if (count > 0)
    difference() {
        solidbarbstack( inside_diameter, count, reinforcement );
    translate([0,0,-0.3]) cylinder( h = inside_diameter * (count + 1), r = inside_diameter * (0.75 - (strength_factor - 1.0)) / 2, $fa = 0.5, $fs = 0.5, $fn=60 );
  }
  else
      difference() {
        cylinder( h = inside_diameter * output_smooth_length, r = 
inside_diameter / 2, $fn=60 );
    translate([0,0,-0.3]) cylinder( h = inside_diameter * output_smooth_length + 0.6, r = inside_diameter * (0.75 - (strength_factor - 1.0)) / 2, $fa = 0.5, $fs = 0.5, $fn=60 );
          //echo( "difference h=", (2*inside_diameter), "r=", inside_diameter/2, "; ir=", inside_diameter * (0.75 - (strength_factor - 1.0)) / 2 );
    }
}

module input_barb( input_diameter, reinforcement = 0 )
{
  barb( input_diameter, input_barb_count, input_strength, reinforcement );
}

module output_barb( input_diameter, output_diameter, jheight, reinforcement = 0 )
{
  // Total height of a barb stack is
  // 0.9 * diameter for each barb overlapping
  // the one above, plus diameter for the topmost;
  // i.e. (D * 0.9 * (count-1)) + D
  input_total_height = (input_barb_count - 1) * 0.9 * input_diameter + input_diameter;
  output_total_height = (output_barb_count - 1) * 0.9 * output_diameter + output_diameter;
  if (output_barb_count == 0) {
      //output_total_height = -4.0 * output_diameter;
      //echo( "jheight=", jheight, "; out-total=", output_total_height, "; in-total=", input_total_height );
    translate( [0,0,input_total_height + jheight] )      barb( output_diameter, output_barb_count, output_strength );
  }
  else {
  translate( [0,0,input_total_height + output_total_height + jheight] ) rotate([0,180,0]) barb( output_diameter, output_barb_count, output_strength, reinforcement );
  }
}

module junction( input_diameter, output_diameter, jheight )
{
  junction_diameter_ratio = (inline_junction_type == "none") ? 1.1 : 1.6;
  lower_junction_diameter_ratio = (inline_junction_type == "none") ? 1.1 : 1.4;
  max_dia = max( input_diameter, output_diameter );
  r1a = max_dia * lower_junction_diameter_ratio / 2;
  r2a = max_dia * junction_diameter_ratio / 2;
  r1b = input_diameter / 2;
  r2b = output_diameter / 2;
  input_total_height = (input_barb_count - 1) * 0.9 * input_diameter + input_diameter;
  {
  //echo( "Junction jheight=", jheight, "; input_dia=", input_diameter, "; output_dia=", output_diameter, "; max_dia=", max_dia, r1a, r2a, r1b, r2b );
  translate( [0,0,input_total_height] ) difference() {
	cylinder( r1 = r1a, r2 = r2a, h = 5, $fa = 0.5, $fs = 0.5 );
	cylinder( r1 = r1b, r2 = r2b, h = (jheight + 1), $fa = 0.5, $fs = 0.5 );
  }
  }
}

module vault( input_diameter, jheight, center_width, center_depth, center_vheight, wall_thickness, output_diameter, center_empty_output )
{
  outside_width = center_width + 2 * wall_thickness;
  outside_depth = center_depth + 2 * wall_thickness;
  outside_vheight = center_vheight + 2 * wall_thickness;
  input_total_height = (input_barb_count - 1) * 0.9 * input_diameter + input_diameter;
  vault_base = input_total_height;
  {
    translate( [0, -outside_depth / 2 + wall_thickness, vault_base - wall_thickness] ) union()
	 {
	   difference() 
      {
        // Start with a solid cube comprising the outside of the vault
        cube( [outside_width,outside_depth,outside_vheight] );
		// Subtract the bottom 2/3 as a cube along with conical sections leading up to the output openings
        union()
        {
            for (i=[1:outputs])
            {
                hull()
                {
                    // Make a hull using the bottom 2/3 of the vault inside wall
                    // and a short cylinder congruent with the bottom of each output
                    translate( [wall_thickness,wall_thickness,wall_thickness] ) cube( [center_width, center_depth, center_vheight * 2 / 3] );
                    translate( [center_empty_output / 2 + output_diameter * vault_connector_ratio / 2 + output_diameter * (i-1) * vault_connector_ratio + wall_thickness, outside_depth / 2, wall_thickness + center_vheight ] ) cylinder( r=output_diameter * 1.25 * output_inside_diameter_ratio / 2, h=0.1, $fn = 60 );
                }
            }
       }
      }
	   // Add supports if requested (not recommended)
       // Supports require printing with a brim (if using ABS)
		if (vault_support == "yes")
	   {
		  support_leg_width = outside_width * 0.48;
		  support_leg_thickness = 0.8; //wall_thickness / 2;
          // First support leg
		  translate([outside_width-support_leg_width,outside_depth-support_leg_thickness,wall_thickness-vault_base]) cube([support_leg_width, support_leg_thickness, vault_base]);
		 // Base connector for first leg //translate([outside_width-support_leg_width,0, wall_thickness-vault_base]) cube([support_leg_width, center_depth + wall_thickness*2, 0.6]);
          // Second leg (going counter-clockwise from first)
          translate([0,outside_depth-support_leg_thickness,wall_thickness-vault_base]) cube([support_leg_width,support_leg_thickness, vault_base]);
          // Base connector for second leg
		  //translate([0,0, wall_thickness-vault_base]) cube([support_leg_width, center_depth + wall_thickness*2, 0.6]);
          // Third leg (end)
           translate([0,wall_thickness,wall_thickness-vault_base]) cube([support_leg_thickness, center_depth, vault_base]);
          // Fourth leg
		  translate([0,0,wall_thickness-vault_base]) cube([support_leg_width, support_leg_thickness, vault_base]);
          // Base connector for fourth leg
          // Fifth leg
          translate([outside_width-support_leg_width,0,wall_thickness-vault_base]) cube([support_leg_width,support_leg_thickness, vault_base]);
          // Base connector for fifth leg
          // Sixth leg (end)
           translate([outside_width-support_leg_thickness,wall_thickness,wall_thickness-vault_base]) cube([support_leg_thickness, center_depth, vault_base]);
          // Additional support legs added 30-Jun-2020
          // Diagonals from corners going in - reduces
          // bridge spaghettification on the bottom of the vault
           translate([outside_width-support_leg_thickness * 1.7,wall_thickness * 0.4,wall_thickness-vault_base]) rotate([0,0,45]) cube([support_leg_thickness, center_depth * 0.36, vault_base]);
           translate([outside_width-support_leg_thickness * 1.7,vault_base + wall_thickness * 0.4,wall_thickness-vault_base]) rotate([0,0,135]) cube([support_leg_thickness, center_depth * 0.36, vault_base]);
           translate([support_leg_thickness * 0.9,wall_thickness * 0.6,wall_thickness-vault_base]) rotate([0,0,315]) cube([support_leg_thickness, center_depth * 0.36, vault_base]);
           translate([support_leg_thickness * 1.7,vault_base + wall_thickness * 0.8,wall_thickness-vault_base]) rotate([0,0,225]) cube([support_leg_thickness, center_depth * 0.36, vault_base]);
		}
    }
  }
}
