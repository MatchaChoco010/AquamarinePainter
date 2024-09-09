#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform image2D store_image;
layout(set = 1, binding = 0) uniform sampler2D gradientTexture;

layout(push_constant, std430) uniform PushConstants {
  int width;
  int height;
  int materialType;
  int r8;
  int g8;
  int b8;
  int a8;
  int padding1;
  vec2 pos0;
  vec2 pos1;
  vec2 pos2;
  int padding2[2];
} pushConstants;

vec4 getColor() {
  vec4 color;
  if (pushConstants.materialType == 0) {
    color.r = float(pushConstants.r8) / 255.0;
    color.g = float(pushConstants.g8) / 255.0;
    color.b = float(pushConstants.b8) / 255.0;
    color.a = float(pushConstants.a8) / 255.0;
  } else if (pushConstants.materialType == 1) {
    vec2 v = pushConstants.pos1 - pushConstants.pos0;
    vec2 uv = vec2(gl_GlobalInvocationID.xy);
    float t = dot(uv - pushConstants.pos0, v) / dot(v, v);
    color = texture(gradientTexture, vec2(t, 0.5));
  } else if (pushConstants.materialType == 2) {
    vec2 a = pushConstants.pos1 - pushConstants.pos0;
    vec2 b = pushConstants.pos2 - pushConstants.pos0;
    float aLength = length(a);
    float bLength = length(b);
    vec2 aNorm = a / aLength;
    vec2 bNorm = b / bLength;
    if (aLength < 0.0001 || bLength < 0.0001) {
      color = texture(gradientTexture, vec2(1.0, 0.5));
    } else {
      vec2 uv = vec2(gl_GlobalInvocationID.xy);
      vec2 p = uv - pushConstants.pos0;
      vec2 pp = dot(p, aNorm) * aNorm + dot(p, bNorm) * bNorm / bLength * aLength;
      float t = length(pp) / aLength;
      color = texture(gradientTexture, vec2(t, 0.5));
    }
  } else if (pushConstants.materialType == 3) {
    vec2 checker_count = vec2(pushConstants.width, pushConstants.height) / 48.0;
    vec2 uv = vec2(gl_GlobalInvocationID.xy) / vec2(pushConstants.width, pushConstants.height);
    float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(uv * checker_count))), 2.0);
    color.rgb = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), checker);
    color.a = 1.0;
  }
  return color;
}

void main() {
  ivec2 size = ivec2(pushConstants.width, pushConstants.height);
  ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

  if (iuv.x >= size.x || iuv.y >= size.y) {
    return;
  }

  vec2 uv = (vec2(iuv) + vec2(0.5)) / vec2(size);

  vec4 color = getColor();

  imageStore(store_image, iuv, color);
}
