#[vertex]
#version 460

layout(location = 0) in vec2 position;

layout(push_constant, std430) uniform PushConstants {
  int width;
  int height;
  int booleanMode;
  int dummy;
} pushConstants;

void main()
{
  vec2 pos = position / vec2(pushConstants.width, pushConstants.height);
  pos = pos * 2.0 - 1.0;
  gl_Position = vec4(pos, 0.0, 1.0);
}


#[fragment]
#version 460

layout (location = 0) out vec4 out_color;

layout(set = 0, binding = 0) uniform sampler2D backBufferImage;

layout(push_constant, std430) uniform PushConstants {
  int width;
  int height;
  int booleanMode;
  int dummy;
} pushConstants;

void main()
{
  vec2 rg = texture(backBufferImage, gl_FragCoord.xy / vec2(pushConstants.width, pushConstants.height)).rg;

  if (pushConstants.booleanMode == 0) {
    // Add
    out_color = vec4(1, 0, 0, 0);
  } else if (pushConstants.booleanMode == 1) {
    // Diff
    out_color = vec4(0, 0, 0, 0);
  } else if (pushConstants.booleanMode == 2) {
    // Intersect first pass
    out_color = vec4(rg.r, 1, 0, 0);
  } else if (pushConstants.booleanMode == 3) {
    // Xor
    out_color = vec4(1 - rg.r, 0, 0, 0);
  } else {
    // Intersect second pass
    out_color = vec4(rg.r* rg.g, 0, 0, 0);
  }
}
