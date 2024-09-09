#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform image2D base_image;
layout(set = 1, binding = 0) uniform sampler2D viewport_image;
layout(set = 2, binding = 0) uniform sampler2D gradientTexture;

const float FIXED_THRESHOLD = 0.0833;
const float RELATIVE_THRESHOLD = 0.166;
const float SUBPIXEL_BLENDING = 0.75;
const float EDGE_STEP_SIZES_ARRAY[10] = float[](
  1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0
);
const float LAST_EDGE_STEP_GUESS = 8.0;

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

float getMaskOffset(vec2 uv, float uOffset, float vOffset) {
  uv += vec2(uOffset + 0.5, vOffset + 0.5) / vec2(pushConstants.width, pushConstants.height);
  return textureLod(viewport_image, uv, 0.0).r;
}

struct MaskNeighbor {
  float center;
  float topLeft;
  float top;
  float topRight;
  float left;
  float right;
  float bottomLeft;
  float bottom;
  float bottomRight;
  float highest;
  float lowest;
  float range;
};

MaskNeighbor getMaskNeighbor(vec2 uv) {
  MaskNeighbor neighbor;
  neighbor.center = getMaskOffset(uv, 0.0, 0.0);
  neighbor.topLeft = getMaskOffset(uv, -1.0, -1.0);
  neighbor.top = getMaskOffset(uv, 0.0, -1.0);
  neighbor.topRight = getMaskOffset(uv, 1.0, -1.0);
  neighbor.left = getMaskOffset(uv, -1.0, 0.0);
  neighbor.right = getMaskOffset(uv, 1.0, 0.0);
  neighbor.bottomLeft = getMaskOffset(uv, -1.0, 1.0);
  neighbor.bottom = getMaskOffset(uv, 0.0, 1.0);
  neighbor.bottomRight = getMaskOffset(uv, 1.0, 1.0);
  neighbor.highest = max(max(max(max(neighbor.center, neighbor.top), neighbor.left), neighbor.right), neighbor.bottom);
  neighbor.lowest = min(min(min(min(neighbor.center, neighbor.top), neighbor.left), neighbor.right), neighbor.bottom);
  neighbor.range = neighbor.highest - neighbor.lowest;
  return neighbor;
}

bool isHorizontal(MaskNeighbor neighbor) {
  float horizontal = 2.0 * abs(neighbor.top + neighbor.bottom - 2.0 * neighbor.center) + abs(neighbor.topLeft+ neighbor.bottomLeft - 2.0 * neighbor.left) + abs(neighbor.topRight + neighbor.bottomRight - 2.0 * neighbor.right);
  float vertical = 2.0 * abs(neighbor.left + neighbor.right - 2.0 * neighbor.center) + abs(neighbor.topLeft + neighbor.topRight - 2.0 * neighbor.top) + abs(neighbor.bottomLeft + neighbor.bottomRight - 2.0 * neighbor.bottom);
  return horizontal >= vertical;
}

struct FxaaEdge {
  bool isHorizontal;
  float pixelStep;
  float maskGradient;
  float otherMask;
};

FxaaEdge getFxaaEdge(MaskNeighbor neighbor) {
  FxaaEdge edge;
  edge.isHorizontal = isHorizontal(neighbor);
  float maskP, maskN;
  if (edge.isHorizontal) {
    edge.pixelStep = 1.0 / float(pushConstants.height);
    maskP = neighbor.top;
    maskN = neighbor.bottom;
  } else {
    edge.pixelStep = 1.0 / float(pushConstants.width);
    maskP = neighbor.left;
    maskN = neighbor.right;
  }
  float gradientP = abs(maskP - neighbor.center);
  float gradientN = abs(maskN - neighbor.center);
  if (gradientP < gradientN) {
    edge.pixelStep = -edge.pixelStep;
    edge.maskGradient = gradientN;
    edge.otherMask = maskN;
  } else {
    edge.maskGradient = gradientP;
    edge.otherMask = maskP;
  }
  return edge;
}

bool canSkipFxaa(MaskNeighbor neighbor) {
  return neighbor.range < max(FIXED_THRESHOLD, RELATIVE_THRESHOLD * neighbor.highest);
}

float getSubpixelBlendFactor(MaskNeighbor neighbor) {
  float filterValue = 2.0 * (neighbor.top + neighbor.bottom + neighbor.left + neighbor.right);
  filterValue += neighbor.topLeft + neighbor.topRight + neighbor.bottomLeft + neighbor.bottomRight;
  filterValue *= 1.0 / 12.0;
  filterValue = abs(filterValue - neighbor.center);
  filterValue = clamp(filterValue / neighbor.range, 0.0, 1.0);
  filterValue = smoothstep(0.0, 1.0, filterValue);
  return filterValue * filterValue * SUBPIXEL_BLENDING;
}

float getEdgeBlendFactor(MaskNeighbor neighbor, FxaaEdge edge, vec2 uv) {
  vec2 edgeUV = uv;
  vec2 uvStep = vec2(0.0);
  if (edge.isHorizontal) {
    uvStep.y += 0.5 * edge.pixelStep;
    uvStep.x = 1.0 / float(pushConstants.width);
  } else {
    uvStep.x += 0.5 * edge.pixelStep;
    uvStep.y = 1.0 / float(pushConstants.height);
  }

  float edgeMask = 0.5 * (neighbor.center + edge.otherMask);
  float gradientThreshold = 0.25 * edge.maskGradient;

  vec2 uvP = edgeUV + uvStep;
  float maskDeltaP = getMaskOffset(uvP, 0.0, 0.0) - edgeMask;
  bool atEndP = abs(maskDeltaP) >= gradientThreshold;

  int i;
  for (i = 0; i < 10 && !atEndP; i++) {
    uvP += uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaP = getMaskOffset(uvP, 0.0, 0.0) - edgeMask;
    atEndP = abs(maskDeltaP) >= gradientThreshold;
  }
  if (!atEndP) {
    uvP = edgeUV + uvStep * LAST_EDGE_STEP_GUESS;
  }

  vec2 uvN = edgeUV - uvStep;
  float maskDeltaN = getMaskOffset(uvN, 0.0, 0.0) - edgeMask;
  bool atEndN = abs(maskDeltaN) >= gradientThreshold;

  for (i = 0; i < 10 && !atEndN; i++) {
    uvN -= uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaN = getMaskOffset(uvN, 0.0, 0.0) - edgeMask;
    atEndN = abs(maskDeltaN) >= gradientThreshold;
  }
  if (!atEndN) {
    uvN = edgeUV - uvStep * LAST_EDGE_STEP_GUESS;
  }

  float distanceToEndP, distanceToEndN;
  if (edge.isHorizontal) {
    distanceToEndP = uvP.x - uv.x;
    distanceToEndN = uv.x - uvN.x;
  } else {
    distanceToEndP = uvP.y - uv.y;
    distanceToEndN = uv.y - uvN.y;
  }

  float distanceToNearestEnd;
  bool deltaSign;
  if (distanceToEndP <= distanceToEndN) {
    distanceToNearestEnd = distanceToEndP;
    deltaSign = maskDeltaP >= 0;
  } else {
    distanceToNearestEnd = distanceToEndN;
    deltaSign = maskDeltaN >= 0;
  }

  if (deltaSign == (neighbor.center - edgeMask >= 0)) {
    return 0.0;
  } else {
    return 0.5 - distanceToNearestEnd / (distanceToEndP + distanceToEndN);
  }
}

float getMask(vec2 uv) {
  MaskNeighbor neighbor = getMaskNeighbor(uv);
  if (canSkipFxaa(neighbor)) {
    return neighbor.center;
  }

  FxaaEdge edge = getFxaaEdge(neighbor);
  float blendFactor = max(getSubpixelBlendFactor(neighbor), getEdgeBlendFactor(neighbor, edge, uv));
  if (edge.isHorizontal) {
    return getMaskOffset(uv, 0.0, blendFactor);
  } else {
    return getMaskOffset(uv, blendFactor, 0.0);
  }
}

vec4 getColor() {
  vec4 color;
  if (pushConstants.materialType == 0) {
    color.r = float(pushConstants.r8) / 255.0;
    color.g = float(pushConstants.g8) / 255.0;
    color.b = float(pushConstants.b8) / 255.0;
    color.a = float(pushConstants.a8) / 255.0;
  } else if (pushConstants.materialType == 1) {
    vec2 v = (pushConstants.pos1 - pushConstants.pos0);
    vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
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
      color = vec4(1.0, 0.0, 1.0, 1.0);
    } else {
      vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
      vec2 p = uv - pushConstants.pos0;
      vec2 pp = dot(p, aNorm) * aNorm + dot(p, bNorm) * bNorm / bLength * aLength;
      float t = length(pp) / aLength;
      color = texture(gradientTexture, vec2(t, 0.5));
    }
  } else if (pushConstants.materialType == 3) {
    vec2 checker_count = vec2(pushConstants.width, pushConstants.height) / 96.0;
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

  float mask = getMask(uv);
  color.a *= mask;

  imageStore(base_image, iuv, color);
}
