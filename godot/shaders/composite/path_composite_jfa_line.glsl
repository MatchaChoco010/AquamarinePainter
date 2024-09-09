#[compute]
#version 460

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform image2D store_image;
layout(rgba32f, set = 1, binding = 0) uniform readonly image2D jfa_image;
layout(set = 2, binding = 0) uniform sampler2D fillGradientTexture;
layout(set = 3, binding = 0) uniform sampler2D lineGradientTexture;

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
    int fillMaterialType;
    int fillR8;
    int fillG8;
    int fillB8;
    int fillA8;
    int padding0;
    vec2 fillPos0;
    vec2 fillPos1;
    vec2 fillPos2;
    int lineMaterialType;
    int lineR8;
    int lineG8;
    int lineB8;
    int lineA8;
    int padding1;
    vec2 linePos0;
    vec2 linePos1;
    vec2 linePos2;
    float lineWidth;
    int padding2;
} pushConstants;


float getFillMaskValue(ivec2 iuv) {
  vec4 jfa = imageLoad(jfa_image, iuv);

  if (jfa.b == 1.0) {
    return 1.0;
  } else {
    return 0.0;
  }
}

float getFillMaskValueOffset(vec2 uv) {
  ivec2 iuv = ivec2(uv * vec2(pushConstants.width, pushConstants.height));
  float maskTopLeft = getFillMaskValue(iuv);
  float maskTopRight = getFillMaskValue(iuv + ivec2(1, 0));
  float maskBottomLeft = getFillMaskValue(iuv + ivec2(0, 1));
  float maskBottomRight = getFillMaskValue(iuv + ivec2(1, 1));
  uv += vec2(0.5) / vec2(pushConstants.width, pushConstants.height);
  vec2 blendFactor = fract(uv * vec2(pushConstants.width, pushConstants.height));
  return mix(
    mix(maskTopLeft, maskTopRight, blendFactor.x),
    mix(maskBottomLeft, maskBottomRight, blendFactor.x),
    blendFactor.y
  );
}

float getLineMaskValue(ivec2 iuv) {
  vec4 jfa = imageLoad(jfa_image, iuv);

  if (
    (jfa.b == 0.0 && jfa.r < pushConstants.lineWidth && jfa.r != -1) ||
    (jfa.a == 0.0 && jfa.g < pushConstants.lineWidth && jfa.g != -1)
  ) {
    return 1.0;
  } else {
    return 0.0;
  }
}

float getLineMaskValueOffset(vec2 uv) {
  ivec2 iuv = ivec2(uv * vec2(pushConstants.width, pushConstants.height));
  float maskTopLeft = getLineMaskValue(iuv);
  float maskTopRight = getLineMaskValue(iuv + ivec2(1, 0));
  float maskBottomLeft = getLineMaskValue(iuv + ivec2(0, 1));
  float maskBottomRight = getLineMaskValue(iuv + ivec2(1, 1));
  uv += vec2(0.5) / vec2(pushConstants.width, pushConstants.height);
  vec2 blendFactor = fract(uv * vec2(pushConstants.width, pushConstants.height));
  return mix(
    mix(maskTopLeft, maskTopRight, blendFactor.x),
    mix(maskBottomLeft, maskBottomRight, blendFactor.x),
    blendFactor.y
  );
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

MaskNeighbor getFillMaskNeighbor(ivec2 iuv) {
  MaskNeighbor neighbor;
  neighbor.center = getFillMaskValue(iuv);
  neighbor.topLeft = getFillMaskValue(iuv + ivec2(-1, -1));
  neighbor.top = getFillMaskValue(iuv + ivec2(0, -1));
  neighbor.topRight = getFillMaskValue(iuv + ivec2(1, -1));
  neighbor.left = getFillMaskValue(iuv + ivec2(-1, 0));
  neighbor.right = getFillMaskValue(iuv + ivec2(1, 0));
  neighbor.bottomLeft = getFillMaskValue(iuv + ivec2(-1, 1));
  neighbor.bottom = getFillMaskValue(iuv + ivec2(0, 1));
  neighbor.bottomRight = getFillMaskValue(iuv + ivec2(1, 1));
  neighbor.highest = max(max(max(max(neighbor.center, neighbor.top), neighbor.left), neighbor.right), neighbor.bottom);
  neighbor.lowest = min(min(min(min(neighbor.center, neighbor.top), neighbor.left), neighbor.right), neighbor.bottom);
  neighbor.range = neighbor.highest - neighbor.lowest;
  return neighbor;
}

MaskNeighbor getLineMaskNeighbor(ivec2 iuv) {
  MaskNeighbor neighbor;
  neighbor.center = getLineMaskValue(iuv);
  neighbor.topLeft = getLineMaskValue(iuv + ivec2(-1, -1));
  neighbor.top = getLineMaskValue(iuv + ivec2(0, -1));
  neighbor.topRight = getLineMaskValue(iuv + ivec2(1, -1));
  neighbor.left = getLineMaskValue(iuv + ivec2(-1, 0));
  neighbor.right = getLineMaskValue(iuv + ivec2(1, 0));
  neighbor.bottomLeft = getLineMaskValue(iuv + ivec2(-1, 1));
  neighbor.bottom = getLineMaskValue(iuv + ivec2(0, 1));
  neighbor.bottomRight = getLineMaskValue(iuv + ivec2(1, 1));
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

float getFillEdgeBlendFactor(MaskNeighbor neighbor, FxaaEdge edge, vec2 uv) {
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
  float maskDeltaP = getFillMaskValueOffset(uvP) - edgeMask;
  bool atEndP = abs(maskDeltaP) >= gradientThreshold;

  int i;
  for (i = 0; i < 10 && !atEndP; i++) {
    uvP += uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaP = getFillMaskValueOffset(uvP) - edgeMask;
    atEndP = abs(maskDeltaP) >= gradientThreshold;
  }
  if (!atEndP) {
    uvP = edgeUV + uvStep * LAST_EDGE_STEP_GUESS;
  }

  vec2 uvN = edgeUV - uvStep;
  float maskDeltaN = getFillMaskValueOffset(uvN) - edgeMask;
  bool atEndN = abs(maskDeltaN) >= gradientThreshold;

  for (i = 0; i < 10 && !atEndN; i++) {
    uvN -= uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaN = getFillMaskValueOffset(uvN) - edgeMask;
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

float getLineEdgeBlendFactor(MaskNeighbor neighbor, FxaaEdge edge, vec2 uv) {
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
  float maskDeltaP = getLineMaskValueOffset(uvP) - edgeMask;
  bool atEndP = abs(maskDeltaP) >= gradientThreshold;

  int i;
  for (i = 0; i < 10 && !atEndP; i++) {
    uvP += uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaP = getLineMaskValueOffset(uvP) - edgeMask;
    atEndP = abs(maskDeltaP) >= gradientThreshold;
  }
  if (!atEndP) {
    uvP = edgeUV + uvStep * LAST_EDGE_STEP_GUESS;
  }

  vec2 uvN = edgeUV - uvStep;
  float maskDeltaN = getLineMaskValueOffset(uvN) - edgeMask;
  bool atEndN = abs(maskDeltaN) >= gradientThreshold;

  for (i = 0; i < 10 && !atEndN; i++) {
    uvN -= uvStep * EDGE_STEP_SIZES_ARRAY[i];
    maskDeltaN = getLineMaskValueOffset(uvN) - edgeMask;
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

float getFillMask(ivec2 iuv) {
  MaskNeighbor neighbor = getFillMaskNeighbor(iuv);
  if (canSkipFxaa(neighbor)) {
    return neighbor.center;
  }

  vec2 uv = vec2(iuv) / vec2(pushConstants.width, pushConstants.height);

  FxaaEdge edge = getFxaaEdge(neighbor);
  float blendFactor = max(getSubpixelBlendFactor(neighbor), getFillEdgeBlendFactor(neighbor, edge, uv));
  if (edge.isHorizontal) {
    vec2 offset = vec2(0.0, blendFactor) / vec2(pushConstants.width, pushConstants.height);
    return getFillMaskValueOffset(uv + offset);
  } else {
    vec2 offset = vec2(blendFactor, 0.0) / vec2(pushConstants.width, pushConstants.height);
    return getFillMaskValueOffset(uv + offset);
  }
}

float getLineMask(ivec2 iuv) {
  MaskNeighbor neighbor = getLineMaskNeighbor(iuv);
  if (canSkipFxaa(neighbor)) {
    return neighbor.center;
  }

  vec2 uv = vec2(iuv) / vec2(pushConstants.width, pushConstants.height);

  FxaaEdge edge = getFxaaEdge(neighbor);
  float blendFactor = max(getSubpixelBlendFactor(neighbor), getLineEdgeBlendFactor(neighbor, edge, uv));
  if (edge.isHorizontal) {
    vec2 offset = vec2(0.0, blendFactor) / vec2(pushConstants.width, pushConstants.height);
    return getLineMaskValueOffset(uv + offset);
  } else {
    vec2 offset = vec2(blendFactor, 0.0) / vec2(pushConstants.width, pushConstants.height);
    return getLineMaskValueOffset(uv + offset);
  }
}

vec4 getFillColor() {
  vec4 color;
  if (pushConstants.fillMaterialType == 0) {
    color.r = float(pushConstants.fillR8) / 255.0;
    color.g = float(pushConstants.fillG8) / 255.0;
    color.b = float(pushConstants.fillB8) / 255.0;
    color.a = float(pushConstants.fillA8) / 255.0;
  } else if (pushConstants.fillMaterialType == 1) {
    vec2 v = pushConstants.fillPos1 - pushConstants.fillPos0;
    vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
    float t = dot(uv - pushConstants.fillPos0, v) / dot(v, v);
    color = texture(fillGradientTexture, vec2(t, 0.5));
  } else if (pushConstants.fillMaterialType == 2) {
    vec2 a = pushConstants.fillPos1 - pushConstants.fillPos0;
    vec2 b = pushConstants.fillPos2 - pushConstants.fillPos0;
    float aLength = length(a);
    float bLength = length(b);
    vec2 aNorm = a / aLength;
    vec2 bNorm = b / bLength;
    if (aLength < 0.0001 || bLength < 0.0001) {
      color = texture(fillGradientTexture, vec2(1.0, 0.5));
    } else {
      vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
      vec2 p = uv - pushConstants.fillPos0;
      vec2 pp = dot(p, aNorm) * aNorm + dot(p, bNorm) * bNorm / bLength * aLength;
      float t = length(pp) / aLength;
      color = texture(fillGradientTexture, vec2(t, 0.5));
    }
  } else if (pushConstants.fillMaterialType == 3) {
    vec2 checker_count = vec2(pushConstants.width, pushConstants.height) / 96.0;
    vec2 uv = vec2(gl_GlobalInvocationID.xy) / vec2(pushConstants.width, pushConstants.height);
    float checker = mod(dot(vec2(1.0), step(vec2(0.5), fract(uv * checker_count))), 2.0);
    color.rgb = mix(vec3(1.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), checker);
    color.a = 1.0;
  }
  return color;
}

vec4 getLineColor() {
  vec4 color;
  if (pushConstants.lineMaterialType == 0) {
    color.r = float(pushConstants.lineR8) / 255.0;
    color.g = float(pushConstants.lineG8) / 255.0;
    color.b = float(pushConstants.lineB8) / 255.0;
    color.a = float(pushConstants.lineA8) / 255.0;
  } else if (pushConstants.lineMaterialType == 1) {
    vec2 v = pushConstants.linePos1 - pushConstants.linePos0;
    vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
    float t = dot(uv - pushConstants.linePos0, v) / dot(v, v);
    color = texture(lineGradientTexture, vec2(t, 0.5));
  } else if (pushConstants.lineMaterialType == 2) {
    vec2 a = pushConstants.linePos1 - pushConstants.linePos0;
    vec2 b = pushConstants.linePos2 - pushConstants.linePos0;
    float aLength = length(a);
    float bLength = length(b);
    vec2 aNorm = a / aLength;
    vec2 bNorm = b / bLength;
    if (aLength < 0.0001 || bLength < 0.0001) {
      color = texture(lineGradientTexture, vec2(1.0, 0.5));
    } else {
      vec2 uv = vec2(gl_GlobalInvocationID.xy) / 2.0;
      vec2 p = uv - pushConstants.linePos0;
      vec2 pp = dot(p, aNorm) * aNorm + dot(p, bNorm) * bNorm / bLength * aLength;
      float t = length(pp) / aLength;
      color = texture(lineGradientTexture, vec2(t, 0.5));
    }
  } else if (pushConstants.lineMaterialType == 3) {
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
  ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

  if (uv.x >= size.x || uv.y >= size.y) {
    return;
  }

  vec4 fillColor = getFillColor();
  vec4 lineColor = getLineColor();
  fillColor.a *= getFillMask(uv);
  lineColor.a *= getLineMask(uv);

  vec4 color;
  color.a = fillColor.a * (1.0 - lineColor.a) + lineColor.a;
  if (color.a != 0) {
    color.rgb = (fillColor.rgb * (1 - lineColor.a) * fillColor.a + lineColor.rgb * lineColor.a) / color.a;
  } else {
    color.rgb = vec3(0);
  }

  imageStore(store_image, uv, color);
}
