shader_type spatial;

uniform float level;
uniform vec2 index;
uniform sampler2D heightmap: filter_nearest;
uniform float height_scale = 100.;

uniform bool is_leaf;
uniform int LOD;
uniform int LOD_min;
uniform float LOD_max_distance;
uniform vec3 global_position;
uniform vec3 camera_position;

uniform float TOP_H = 0.0;
uniform float BOTTOM_H = 0.0;
uniform float LEFT_H = 0.0;
uniform float RIGHT_H = 0.0;

varying float LOD_TOP;
varying float LOD_BOTTOM;
varying float LOD_LEFT;
varying float LOD_RIGHT;

float get_height(vec2 uv) {
	float value =  texture(heightmap, uv).r * height_scale;
	return value;
}


int calc_LOD(vec3 next_leaf) {
	float distance_to = distance(camera_position, next_leaf);

  int lod = LOD_min;

  if (distance_to > 1024.0) {
    lod = LOD_min;
  } else if (distance_to > 896.0) {
    lod = 5;
  } else if (distance_to > 640.0) {
    lod = 4;
  } else if (distance_to > 512.0) {
    lod = 3;
  } else if (distance_to > 256.0) {
    lod = 2;
  } else if (distance_to > 128.0) {
    lod = 1;
  } else {
    lod = 0;
  }

	// if (distance_to > LOD_max_distance) {
	// 	return LOD_min;
	// }

	// for (int x = 0; x <= LOD_min; ++x) {
	// 	if (distance_to < float((x + 1) * 128)) {
	// 		return x;
	// 	}
	// }

	return lod;

}


float calc_middle(vec2 uv, vec2 offset) {
	float h1 = get_height(vec2(uv.x - offset.x, uv.y - offset.y));
	float h2 = get_height(vec2(uv.x + offset.x, uv.y + offset.y));
	return mix(h1, h2, 0.5);
}

void vertex() {

	float pixel = 1.0 / 2049.;
	float half_pixel = pixel / 2.0;
	float factor = pow(2.0, level);

	float edges = 2048. / factor;

	int x = int(UV.x * float(edges));
    int y = int(UV.y * float(edges));

	vec2 offset = level > 0.0
		? index * (pixel * edges)
		: vec2(0,0);


	UV = offset + vec2(half_pixel, half_pixel) + vec2(float(x) * pixel, float(y) * pixel);

	VERTEX.y = get_height(UV);

	float vertex_step = pixel * pow(2.0, float(LOD));
	float shift = 128.0;

	// LOD
	if (is_leaf) {
		vec3 leaf_top    = global_position + vec3(     0,    TOP_H, -shift);
		vec3 leaf_bottom = global_position + vec3(     0, BOTTOM_H,  shift);
		vec3 leaf_left   = global_position + vec3(-shift,   LEFT_H,      0);
		vec3 leaf_right  = global_position + vec3( shift,  RIGHT_H,      0);
		
		int LOD_T = calc_LOD(leaf_top);
		int LOD_B = calc_LOD(leaf_bottom);
		int LOD_L = calc_LOD(leaf_left);
		int LOD_R = calc_LOD(leaf_right);
		
		LOD_TOP = float(LOD_T);
		LOD_BOTTOM = float(LOD_B);
		LOD_LEFT = float(LOD_L);
		LOD_RIGHT = float(LOD_R);
		
		if (VERTEX_ID % 2 != 0) {

			if (LOD_T > LOD) {
				if (UV2.y == 0.0) {
					VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
				}
			}

			if (LOD_B > LOD) {
				if (UV2.y > 0.99) {
					VERTEX.y = calc_middle(UV, vec2(vertex_step, 0));
				}
			}

			if (LOD_L > LOD) {
				if (UV2.x == 0.0) {
					VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
				}
			}

			if (LOD_R > LOD) {
				if (UV2.x > 0.99) {
					VERTEX.y = calc_middle(UV, vec2(0, vertex_step));
				}
			}

		}
	}
}

void fragment() {
	ALBEDO = texture(heightmap, UV).rrr;
	float edge = 0.04;

	NORMAL_MAP = texture(heightmap, UV).gba;

	if (UV2.x < edge || UV2.y < edge) {
		//ALBEDO = color;
		ALBEDO += vec3(1.,0,0);
	}
	
	edge = 0.08;

	if (is_leaf) {
		
		float lod = float(LOD);
		
		if (LOD_TOP > lod && UV2.y < edge) {
			ALBEDO = vec3(1.,0,0);
		}

		if (LOD_BOTTOM > lod && UV2.y > 1.0 - edge) {
			ALBEDO = vec3(1.,0,1.);
		}

		if (LOD_LEFT > lod && UV2.x < edge) {
			ALBEDO = vec3(0,1,0);
		}

		if (LOD_RIGHT > lod && UV2.x > 1.0 - edge) {
			ALBEDO = vec3(0,0,1.);
		}
		
	}
	

	//if (LOD_0 > 0) {
		//ALBEDO = vec3(0,0.4,0);
	//}
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
