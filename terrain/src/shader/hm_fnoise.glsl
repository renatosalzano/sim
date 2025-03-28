#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r16f, binding = 0) restrict uniform image2D heightmap;
layout(set = 0, binding = 1, std430) restrict buffer Grid {
  float data[];
}
grid;

#include "FastNoiseLite.glsl"

void main() {

  fnl_state state = fnlCreateState(0);

  state.noise_type = FNL_NOISE_OPENSIMPLEX2S;
  state.fractal_type = FNL_FRACTAL_RIDGED;
	state.frequency = .001;
	state.octaves = 5;
	state.lacunarity = 2.;
	state.gain = .5;
  state.weighted_strength = .5;


  ivec2 coords = ivec2(gl_GlobalInvocationID.xy);

  
  vec2 index = vec2(grid.data[0], grid.data[1]);
  vec2 size = vec2(grid.data[2], grid.data[2]);

  // float pixel = 0.0004;

  vec2 offset = (index * (size - 1.));
  vec2 point = vec2(coords) + offset;
  point *= 0.8;

  float value = fnlGetNoise2D(state, point.x, point.y);

  value = value * .5 + .5;

  imageStore(heightmap, coords, vec4(value, 0., 0., 1.0));
}