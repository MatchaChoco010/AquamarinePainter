#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, set = 0, binding = 0) uniform image2D store_image;
layout(rgba8, set = 1, binding = 0) uniform readonly image2D viewport_image;


layout(push_constant, std430) uniform PushConstants {
    int width;
    int height;
    int padding0;
    int padding1;
} pushConstants;

void main() {
  ivec2 size = ivec2(pushConstants.width, pushConstants.height);
  ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

  if (uv.x >= size.x || uv.y >= size.y) {
    return;
  }

  vec4 viewport = imageLoad(viewport_image, uv);

  vec4 init;
  if (viewport.r == 1.0) {
    init = vec4(0.0, -1.0, 1.0, 0.0);
  } else {
    init = vec4(-1.0, 0.0, 0.0, 1.0);
  }
  imageStore(store_image, uv, init);
}
