// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "CS01_03/Scan_Code"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimMin ("RimMin", Range(0, 1)) = 0
        _RimMax ("RimMax", Range(0, 1)) = 1
        _InnerColor("InnerColor", Color) = (0,0,0,0)
        _RimColor("_RimColor", Color) = (0,0,1,1)
        _RimIntensity("_RimIntensity", float) = 1
        _FlowTex ("FlowTex", 2D) = "white" {}
        _FlowUV("_FlowUV", Vector) = (0,0,0,0)
        _InnerAlpha ("_InnerAlpha", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}
        LOD 100
        
        Pass
        {
            ZWrite On
            ColorMask 0
        }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                float3 pivot_world : TEXCOORD3;
            };

            sampler2D _MainTex, _FlowTex;
            float4 _MainTex_ST, _FlowTex_ST, _FlowUV;
            float _RimMin, _RimMax, _RimIntensity, _InnerAlpha;
            fixed4 _InnerColor, _RimColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                float3 pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos_world = pos_world;
                o.uv = v.uv;
                o.pivot_world = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float3 normal = i.normal;
                float3 view_world = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float NdotV = saturate(dot(normal, view_world));
                half frenel = 1 - NdotV;
                frenel = smoothstep(_RimMin, _RimMin + _RimMax, frenel);
                half emiss = tex2D(_MainTex, i.uv).r;
                emiss = pow(emiss, 5);

                half final_frenel = saturate(frenel + emiss);

                half3 rim_color = lerp(_InnerColor, _RimColor.xyz * _RimIntensity, final_frenel);
                half rim_alpha = lerp(_InnerAlpha, 1, final_frenel);

                half2 uv_flow = (i.pos_world.xy - i.pivot_world.xy) * _FlowUV.zw;
                uv_flow += _Time.y * _FlowUV.xy;
                fixed3 flowTex = tex2D(_FlowTex, uv_flow);

                fixed4 col;
                col.rgb = rim_color + flowTex;
                col.a = rim_alpha + flowTex.r;
                

                return col;
            }
            ENDCG
        }
    }
}
