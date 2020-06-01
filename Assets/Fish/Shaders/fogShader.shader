Shader "Unlit/fogShader"
{
    Properties
    {
		_FogCenter("Center / Raio", vector) = (0,0,0,0.5)
		_FogColor("Fog Color", Color) = (1,1,1,1)
		_InnerRatio("thick of fog", Range(0.0, 1)) = 0.5
		_Density("Density", Range(0,1)) = 0.5
    }
    SubShader
    {
		Tags{ "Queue" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off Lighting Off ZWrite Off
		ZTest Always


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                float3 view : TEXCOORD0;
                float4 pos : SV_POSITION;
				float4 projPos : TEXCOORD1;
				float4 ogPos : TEXCOORD2;
            };

		float4 _FogCenter;
		float4 _FogColor;
		float _InnerRatio;
		float _Density;
		sampler2D _CameraDepthTexture; 

            v2f vert (appdata_base v)
            {
				v2f o;
				float4 wPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.view = wPos.xyz - _WorldSpaceCameraPos;
				o.projPos = ComputeScreenPos(o.pos);
				o.ogPos = mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));

				float infrontOf = (o.pos.z / o.pos.w) > 0;
				o.pos.z *= infrontOf;

				return o;
            }



			float CallCulateFogIntensity(
				float3 sphereCenter,
				float  sphereRadius,
				float  innerRatio,
				float  dens,
				float3 cameraPosition,
				float3 viewDirection,
				float maxDistance)
			{		


				//calculate ray-Shere intersection
				float3 localCam = cameraPosition - sphereCenter;
				//float a = pow(viewDirection,2)
				float a = dot(viewDirection, viewDirection); //dot Product of itself
				float b = 2 * dot(viewDirection, localCam);
				float c = dot(localCam, localCam) - sphereRadius * sphereRadius;

				//calcular o descreminante
				float d = b * b - 4 * a * c;

				if (d <= 0.0f)
					return 0;
				//Se passarmos este ponto...

				//Vamos usar a formula resolvente
				float DSqrt = sqrt(d);
				float dist = max((-b - DSqrt) / 2 * a, 0);
				float dist2 = max((-b + DSqrt) / 2 * a, 0);

				//o quanto até back
				float backDepth = min(maxDistance, dist2); //SE não existir ao menos temos sampler

														   //O quao gross é o nevoeiro
				float sampl = dist;

				//quantos passos vamos dar de lado ao outro da esfera
				//a distancia em 10 passos
				//float step_Distance = (dist2 - dist)/10;
				float step_Distance = (backDepth - dist) / 10;
				float step_contribution = dens;

				//um valor centroid
				float centerValue = 1 / (1 - innerRatio);

				//começa clear
				float clarity = 1;

				//Marching - 0 10 é o numero de passos

				for (int seg = 0; seg < 50; seg++) {
					float3 position = localCam + viewDirection * sampl;
					float val = saturate(centerValue * (1 - length(position) / sphereRadius));
					float fog_amount = saturate(val * step_contribution);
					clarity *= (1 - fog_amount);
					sampl += step_Distance;
				}
				return 1 - clarity;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				fixed4 col = half4(1,1,1,1);

			float deph = LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos))));

			float3 viewdirection = normalize(i.view);

			

			float fogD = CallCulateFogIntensity(
				i.ogPos.xyz,
				_FogCenter.w,
				_InnerRatio,
				_Density,
				_WorldSpaceCameraPos,
				viewdirection,
				deph);



			col.rgb = _FogColor.rgb;
			col.a = fogD;
			return col;
			}

            ENDCG
        }
    }
}
