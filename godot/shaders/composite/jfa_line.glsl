#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, set = 0, binding = 0) uniform image2D store_image;
layout(rgba32f, set = 1, binding = 0) uniform readonly image2D read_image;

layout(push_constant, std430) uniform PushConstants {
    int width;
    int height;
    int space;
    int padding1;
} pushConstants;

const float ROOT2 = 1.41421356237;

void main() {
  ivec2 size = ivec2(pushConstants.width, pushConstants.height);
  ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

  if (uv.x >= size.x || uv.y >= size.y) {
    return;
  }

  float space = float(pushConstants.space);
  float spaceRoot2 = space * ROOT2;

  vec4 valueCenter = imageLoad(read_image, uv);

  ivec2 topLeftUV = ivec2(max(uv.x - space, 0), max(uv.y - space, 0));
  vec4 valueTopLeft = imageLoad(read_image, topLeftUV);

  ivec2 topUV = ivec2(uv.x, max(uv.y - space, 0));
  vec4 valueTop = imageLoad(read_image, topUV);

  ivec2 topRightUV = ivec2(min(uv.x + space, size.x - 1), max(uv.y - space, 0));
  vec4 valueTopRight = imageLoad(read_image, topRightUV);

  ivec2 leftUV = ivec2(max(uv.x - space, 0), uv.y);
  vec4 valueLeft = imageLoad(read_image, leftUV);

  ivec2 rightUV = ivec2(min(uv.x + space, size.x - 1), uv.y);
  vec4 valueRight = imageLoad(read_image, rightUV);

  ivec2 bottomLeftUV = ivec2(max(uv.x - space, 0), min(uv.y + space, size.y - 1));
  vec4 valueBottomLeft = imageLoad(read_image, bottomLeftUV);

  ivec2 bottomUV = ivec2(uv.x, min(uv.y + space, size.y - 1));
  vec4 valueBottom = imageLoad(read_image, bottomUV);

  ivec2 bottomRightUV = ivec2(min(uv.x + space, size.x - 1), min(uv.y + space, size.y - 1));
  vec4 valueBottomRight = imageLoad(read_image, bottomRightUV);

  float minR = valueCenter.r;
  if (valueTopLeft.r != -1.0 && (minR == -1.0 || valueTopLeft.r + spaceRoot2 < minR)) {
    minR = valueTopLeft.r + spaceRoot2;
  }
  if (valueTop.r != -1.0 && (minR == -1.0 || valueTop.r + space < minR)) {
    minR = valueTop.r + space;
  }
  if (valueTopRight.r != -1.0 && (minR == -1.0 || valueTopRight.r + spaceRoot2 < minR)) {
    minR = valueTopRight.r + spaceRoot2;
  }
  if (valueLeft.r != -1.0 && (minR == -1.0 || valueLeft.r + space < minR)) {
    minR = valueLeft.r + space;
  }
  if (valueRight.r != -1.0 && (minR == -1.0 || valueRight.r + space < minR)) {
    minR = valueRight.r + space;
  }
  if (valueBottomLeft.r != -1.0 && (minR == -1.0 || valueBottomLeft.r + spaceRoot2 < minR)) {
    minR = valueBottomLeft.r + spaceRoot2;
  }
  if (valueBottom.r != -1.0 && (minR == -1.0 || valueBottom.r + space < minR)) {
    minR = valueBottom.r + space;
  }
  if (valueBottomRight.r != -1.0 && (minR == -1.0 || valueBottomRight.r + spaceRoot2 < minR)) {
    minR = valueBottomRight.r + spaceRoot2;
  }

  float minG = valueCenter.g;
  if (valueTopLeft.g != -1.0 && (minG == -1.0 || valueTopLeft.g + spaceRoot2 < minG)) {
    minG = valueTopLeft.g + spaceRoot2;
  }
  if (valueTop.g != -1.0 && (minG == -1.0 || valueTop.g + space < minG)) {
    minG = valueTop.g + space;
  }
  if (valueTopRight.g != -1.0 && (minG == -1.0 || valueTopRight.g + spaceRoot2 < minG)) {
    minG = valueTopRight.g + spaceRoot2;
  }
  if (valueLeft.g != -1.0 && (minG == -1.0 || valueLeft.g + space < minG)) {
    minG = valueLeft.g + space;
  }
  if (valueRight.g != -1.0 && (minG == -1.0 || valueRight.g + space < minG)) {
    minG = valueRight.g + space;
  }
  if (valueBottomLeft.g != -1.0 && (minG == -1.0 || valueBottomLeft.g + spaceRoot2 < minG)) {
    minG = valueBottomLeft.g + spaceRoot2;
  }
  if (valueBottom.g != -1.0 && (minG == -1.0 || valueBottom.g + space < minG)) {
    minG = valueBottom.g + space;
  }
  if (valueBottomRight.g != -1.0 && (minG == -1.0 || valueBottomRight.g + spaceRoot2 < minG)) {
    minG = valueBottomRight.g + spaceRoot2;
  }

  float b = valueCenter.b;
  float a = valueCenter.a;

  vec4 value = vec4(minR, minG, b, a);
  imageStore(store_image, uv, value);
}
