//
//  Shaders.metal
//  RTIScan
//
//  Created by yang yuan on 3/9/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),      /// (x, y, depth, W)
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));
    
    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ), /// (x, y)
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 displayTexture(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]],
                              texture2d<float, access::sample> texture2 [[ texture(1) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    half4 base = half4(texture.sample(s, mappingVertex.textureCoordinate));
    half4 overlay = half4(texture2.sample(s, mappingVertex.textureCoordinate));
    
    return max(base, overlay);
}

/*
vertex float4 basic_vertex(                           // 1
    const device packed_float3* vertex_array [[ buffer(0) ]], // 2
    unsigned int vid [[ vertex_id ]]) {                 // 3
    return float4(vertex_array[vid], 1.0);              // 4
}

fragment half4 basic_fragment() { // 1
    return half4(1.0);              // 2
}
*/
