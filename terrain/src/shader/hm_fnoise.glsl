#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r16f, binding = 0) restrict uniform image2D heightmap;
layout(set = 0, binding = 1, std430) restrict buffer Grid {
  float data[];
}
grid;

#include "FastNoiseLite.glsl"

float get_noise(vec2 point, fnl_state state) {
  float value = fnlGetNoise2D(state, point.x, point.y);
  return (value / 2.0) + 0.5;
}

void main() {

  fnl_state cellular = fnlCreateState(0);

  cellular.noise_type = FNL_NOISE_CELLULAR;
  cellular.fractal_type = FNL_FRACTAL_NONE;
  cellular.cellular_distance_func = FNL_CELLULAR_DISTANCE_EUCLIDEANSQ;
  // cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_CELLVALUE;
  cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE2MUL;
  // cellular.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE;
  cellular.domain_warp_type = FNL_DOMAIN_WARP_BASICGRID;

  cellular.frequency = 0.0005;


  // fnl_state diff = fnlCreateState(0);

  // diff.noise_type = FNL_NOISE_CELLULAR;
  // diff.fractal_type = FNL_FRACTAL_NONE;
  // diff.cellular_distance_func = FNL_CELLULAR_DISTANCE_EUCLIDEANSQ;
  // diff.cellular_return_type = FNL_CELLULAR_RETURN_TYPE_DISTANCE;
  // diff.domain_warp_type = FNL_DOMAIN_WARP_BASICGRID;
  // diff.domain_warp_amp = 50.0;
  // diff.frequency = 0.001;


  fnl_state ridged = fnlCreateState(0);

  ridged.noise_type = FNL_NOISE_OPENSIMPLEX2S;
  ridged.fractal_type = FNL_FRACTAL_RIDGED;
	ridged.frequency = .001;
	ridged.octaves = 5;
	ridged.lacunarity = 2.;
	ridged.gain = .5;
  ridged.weighted_strength = .5;

  fnl_state simplex = fnlCreateState(0);

  simplex.noise_type = FNL_NOISE_OPENSIMPLEX2S;
	simplex.frequency = .0005;
	simplex.octaves = 8;
	simplex.lacunarity = 2.;
	simplex.gain = .5;


  fnl_state simplex2 = fnlCreateState(123);

  simplex.noise_type = FNL_NOISE_OPENSIMPLEX2S;
	simplex.frequency = .0005;
	simplex.octaves = 0;
  // simplex.weighted_strength = .5;


  ivec2 coords = ivec2(gl_GlobalInvocationID.xy);

  
  vec2 index = vec2(grid.data[0], grid.data[1]);
  vec2 size = vec2(grid.data[2], grid.data[2]);

  // float pixel = 0.0004;

  vec2 offset = (index * (size - 1.));
  vec2 point = vec2(coords) + offset;
  point *= 0.8;

  float value = get_noise(point, simplex) * 0.25;

  value = pow(value, 1.3);

  float cellular_value = get_noise(point, cellular);

  float ridged_value = get_noise(point, ridged) * 3.;

  value = mix(value, ridged_value, cellular_value);

  // value = (value / cellular_value) + ridged_value;

  // value = fnlGetNoise2D(simplex, point.x, point.y) / cellular_value * .5;
  // value += fnlGetNoise2D(ridged, point.x, point.y) * cellular_value * .5;
  // value = fnlGetNoise2D(ridged, point.x, point.y);

  // value = cellular_value;
  // value = value * .5 + .5;

  imageStore(heightmap, coords, vec4(value, 0., 0., 1.0));
}