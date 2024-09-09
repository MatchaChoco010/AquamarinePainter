#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform image2D base_image;
layout(rgba8, set = 1, binding = 0) uniform readonly image2D foreground_image;
layout(rgba8, set = 2, binding = 0) uniform readonly image2D clipping_image;

layout(push_constant, std430) uniform PushConstants {
    int blendMode;
    int clipping;
    int width;
    int height;
    int alpha;
    int clippingAlpha;
    int mirror;
} pushConstants;

void main() {
  ivec2 size = ivec2(pushConstants.width, pushConstants.height);
  ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

  if (uv.x >= size.x || uv.y >= size.y) {
    return;
  }

  vec4 base = imageLoad(base_image, uv);

  if (pushConstants.mirror == 1) {
    uv.x = size.x - uv.x - 1;
  }

  vec4 foreground = imageLoad(foreground_image, uv);
  vec4 clipping = imageLoad(clipping_image, uv);

  foreground.a *= float(pushConstants.alpha) / 100.0;
  clipping.a *= float(pushConstants.clippingAlpha) / 100.0;
  if (pushConstants.clipping == 1) {
    foreground.a *= clipping.a;
  }

  // Porter Dugg, Source Over
  float f_b = 1 - foreground.a;
  float f_f = 1;


  vec4 color;
  color.a = base.a * f_b + foreground.a * f_f;

  vec3 blendColor;

  switch (pushConstants.blendMode) {
    case 0:  // Normal
      blendColor = foreground.rgb;
      break;
    case 1:  // Add
      blendColor =min(vec3(1), base.rgb + foreground.rgb);
      break;
    case 2:  // Multiply
      blendColor = base.rgb * foreground.rgb;
      break;
    case 3:  // Screen
      blendColor = 1 - (1 - base.rgb) * (1 - foreground.rgb);
      break;
    case 4:  // Overlay
      if (base.a < 0.5) {
        blendColor = 2 * base.rgb * foreground.rgb;
      } else {
        blendColor = 1 - 2 * (1 - base.rgb) * (1 - foreground.rgb);
      }
      break;
  }

  vec3 color_prime = blendColor * base.a + foreground.rgb * (1 - base.a);
  color.rgb = (base.rgb * f_b * base.a + color_prime * f_f * foreground.a) / color.a;

  if (pushConstants.clipping == 0) {
    if (color.a == 0.0) {
      color.rgb = vec3(0.0);
    }
  } else {
    if (color.a == 0.0) {
      return;
    }
  }


  if (pushConstants.mirror == 1) {
    uv.x = size.x - uv.x - 1;
  }

  imageStore(base_image, uv, color);
}
