#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r8, binding = 0) restrict uniform image2D heightmap;
layout(set = 0, binding = 1, std430) restrict buffer Grid {
  float data[];
}
grid;

// from https://github.com/patriciogonzalezvivo/lygia
vec4 mod289(const in vec4 x) { return x - floor(x * (1. / 289.)) * 289.; }
vec4 permute(const in vec4 v) { return mod289(((v * 34.0) + 1.0) * v); }
vec2 quintic(const in vec2 v)  { return v*v*v*(v*(v*6.0-15.0)+10.0); }
vec4 taylorInvSqrt(in vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

// Classic Perlin noise, periodic variant
float pnoise(in vec2 P, in vec2 rep) {
    vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    Pi = mod(Pi, rep.xyxy); // To create noise with explicit period
    Pi = mod289(Pi);        // To avoid truncation effects in permutation
    vec4 ix = Pi.xzxz;
    vec4 iy = Pi.yyww;
    vec4 fx = Pf.xzxz;
    vec4 fy = Pf.yyww;

    vec4 i = permute(permute(ix) + iy);

    vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
    vec4 gy = abs(gx) - 0.5 ;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;

    vec2 g00 = vec2(gx.x,gy.x);
    vec2 g10 = vec2(gx.y,gy.y);
    vec2 g01 = vec2(gx.z,gy.z);
    vec2 g11 = vec2(gx.w,gy.w);

    vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;

    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));

    vec2 fade_xy = quintic(Pf.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}


void main() {

  ivec2 coords = ivec2(gl_GlobalInvocationID.xy);

  vec2 index = vec2(grid.data[0], grid.data[1]);
  vec2 size = vec2(grid.data[2], grid.data[2]);

  float pixel = 0.0004;

  vec2 offset = (index * (size - 1.));
  vec2 point = vec2(coords) + offset;
  point *= pixel;

  // float value = pnoise((point * pixel) * 50., vec2(1.5, 3.4));

  int max_octaves = 8;

  float value = 0.0;
  float freq = 2.0;
  float amplitude = 1.0;
  float persistence = 0.5;
  vec2 period = vec2(1.5, 3.4);

  for (int octaves = 0; octaves < max_octaves; octaves++) {
    value += pnoise(point * freq, period) * amplitude;
    freq *= 2.0;
    amplitude *= persistence;
  }

  // float value = pnoise(uv * 10.0, vec2(10.0, 10.0));

  value = (value + 1.0) * 0.5;
  value = smoothstep(0.0, 1.0, value);

  imageStore(heightmap, coords, vec4(value, 0.0, 0.0, 1.));
}