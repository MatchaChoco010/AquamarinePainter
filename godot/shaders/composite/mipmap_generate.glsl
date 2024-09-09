#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform image2D store_image;
layout(set = 1, binding = 0) uniform sampler2D input_image;

layout(push_constant, std430) uniform PushConstants {
    int width;
    int height;
    int padding0;
    int padding1;
} pushConstants;

void main() {
  ivec2 size = ivec2(pushConstants.width, pushConstants.height);
  ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

  if (iuv.x >= size.x || iuv.y >= size.y) {
    return;
  }

  vec2 uv = (vec2(iuv) + vec2(0.5)) / vec2(size);

  vec4 color = texture(input_image, uv);
  imageStore(store_image, iuv, color);
}
