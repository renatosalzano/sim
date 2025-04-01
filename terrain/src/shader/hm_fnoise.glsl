#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, binding = 0) restrict uniform image2D heightmap;
layout(set = 0, binding = 1, std430) restrict buffer Grid {
  float data[];
}
grid;

#include "FastNoiseLite.glsl"

float get_noise(vec2 point, fnl_state state) {
  float value = fnlGetNoise2D(state, point.x, point.y);
  return (value / 2.0) + 0.5;
}

float get_height(vec2 point) {

  fnl_state cellular = fnlCreateState(0);

  cellular.noise_type = FNL_NOISE_CELLULAR;
  cellular.fractal_type = FNL_FRACTAL_NONE;
  cellular.cellular_distance_func = FNL_CELLULAR_DISTANCE_EUCLIDEANSQ;
  // cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_CELLVALUE;
  cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE2MUL;
  // cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE;
  cellular.frequency = 0.0005;

  cellular.domain_warp_type = FNL_DOMAIN_WARP_BASICGRID;
  cellular.domain_warp_amp = 100.;
  fnlDomainWarp2D(cellular, point.x, point.y);


  fnl_state ridged = fnlCreateState(1);

  ridged.noise_type = FNL_NOISE_OPENSIMPLEX2S;
  ridged.fractal_type = FNL_FRACTAL_RIDGED;
	ridged.frequency = .001;
	ridged.octaves = 8;
	ridged.lacunarity = 2.;
	ridged.gain = .5;
  ridged.weighted_strength = .3;

  fnl_state simplex = fnlCreateState(1);

  simplex.noise_type = FNL_NOISE_OPENSIMPLEX2S;
	simplex.frequency = .01;
	simplex.octaves = 8;
	simplex.lacunarity = 2.;
	simplex.gain = .5;

  simplex.domain_warp_type = FNL_DOMAIN_WARP_BASICGRID;
  simplex.domain_warp_amp = 50.;
  fnlDomainWarp2D(simplex, point.x, point.y);

  float value = get_noise(point * 0.01, simplex) * 0.25;

  value = pow(value, 2.5);

  float cellular_value = get_noise(point, cellular);

  float ridged_value = get_noise(point, ridged) * 4.;
  
  value = mix(value, ridged_value, cellular_value);
  
  return value;
}

vec3 get_normal(vec2 point, float height_scale) {

  float t = get_height(point - vec2( 0., -1.));
	float b = get_height(point - vec2( 0.,  1.));
	float l = get_height(point - vec2(-1.,  0.));
	float r = get_height(point - vec2( 1.,  0.));

	float dx = (r - l) * 0.5 * height_scale;
	float dy = (t - b) * 0.5 * height_scale;
	float dz = 1.0;

	vec3 n = normalize(vec3(dx, dy, dz));

	vec3 normal_color = vec3(
    (n.x + 1.0) * 0.5, 
    (n.y + 1.0) * 0.5, 
    (n.z + 1.0) * 0.5
  );

  return normal_color;
}

void main() {

  ivec2 coords = ivec2(gl_GlobalInvocationID.xy);
  
  vec2 index = vec2(grid.data[0], grid.data[1]);
  vec2 size = vec2(grid.data[2], grid.data[2]);

  // float pixel = 0.0004;

  vec2 offset = (index * (size - 1.));
  vec2 point = vec2(coords) + offset;
  point *= 0.8;

  float height = get_height(point);

  vec3 normal = get_normal(point, 400.0);

  imageStore(heightmap, coords, vec4(height, normal.x, normal.y, normal.z));
}