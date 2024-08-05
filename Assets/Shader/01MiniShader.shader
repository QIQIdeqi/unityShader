// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "CS0102/01MiniShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}
        _float("Float", Float) = 0.0
        _Range("Range", Range(0,1)) = 0.0
        _Vector("Vector", Vector) = (1,1,1,1)
        _Color("Color", Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", Float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Queue" "Queue" = "Transparent"}
        LOD 100
        Cull [_CullMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
                
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 pos_uv : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 view : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Range;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.view = normalize(_WorldSpaceCameraPos.xyz - pos_world);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, (i.uv.x, i.uv.y + _Time.y * 0.5));
                fixed4 noiseTex = tex2D(_NoiseTex, (i.uv.z, i.uv.w + _Time.y * 0.8));
                // clip(col.r - _Range);
                col.a = smoothstep(col.r, col.r + _Range, noiseTex.r - col.r) * 2;
                float rim = 1 - dot(normalize(i.normal), normalize(i.view));
                col = col * rim + rim;
                return col;
            }
            ENDCG
        }
    }
}
