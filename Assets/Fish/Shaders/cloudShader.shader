Shader "Unlit/cloudShader"
{
    Properties
    {
		_Scale("Scale", Range(0.1, 10)) = 2.0
		_StepScale("Step Scale", Range(0.1, 100)) = 1
		_Steps("Steps", Range(1,200)) = 60
		_MinHeight("_MinHeight", Range(0.0, 5)) = 0
		_MaxHeight("_MaxHeight", Range(6, 10)) = 10.0
		_FadeDist("Fade distance", Range(0.0, 10.0)) = 0.5
		_SunDir("Sun Direction", vector) = (1,0,0,0)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float3 view : TEXCOORD0;
				float4 projPos : TEXCOORD1;
				float3 wPos : TEXCOORD2;
            };

			float _Scale;
			float _StepScale;
			float _Steps;
			float _MinHeight;
			float _MaxHeight;
			float _FadeDist;
			float4 _SunDir;

			float random(float3 value, float3 dotDir) {
				float3 smallV = sin(value); //smoth random
				float random = dot(smallV, dotDir);
				random = frac(sin(random)* 165432.432122); //inventei o numero
				return random;
			}

			float3 random3D(float3 value) {
				return float3(random(value, float3(12.777, 65.25, 39.7254)),
					random(value, float3(40.777, 25.25, 39.7254)),
					random(value, float3(28.777, 35.25, 90.7254)));
			}

			float noise3d(float value)
			{
				value *= _Scale;
				value.x += _Time.b;	//Dá movimento às nuvens!

				float3 interp = frac(value);
				interp = smoothstep(0.0, 1.0, interp);

				float3 ZValues[2];

				for (int z = 0; z <= 1; z++)
				{
					float3 YValues[2];
					for (int y = 0; y <= 1; y++)
					{
						float3 XValues[2];
						for (int x = 0; x <= 1; x++)
						{
							float3 cell = floor(value) + float3(x, y, z); //Todas as diferentes combinacoes de x y z
							XValues[x] = random3D(cell);
						}
						YValues[y] = lerp(XValues[0], XValues[1], interp.x);
					}
					ZValues[z] = lerp(YValues[0], YValues[1], interp.y);
				}

				float noise = -1.0 + 2 * lerp(ZValues[0], ZValues[1], interp.z);

				return noise;
			}

			fixed4 integrate(fixed4 sum, float diffuse, float density, fixed4 bgcol, float t) {
				fixed3 lighting = fixed3(0.65, 0.68, 0.7) * 1.3 + 0.5 * fixed3(0.7, 0.5, 0.3) * diffuse;
				fixed3 colrgb = lerp(fixed3(1.0, 0.95, 0.7), fixed3(0.65, 0.65, 0.65), density);

				fixed4 col = fixed4(colrgb.rgb, density);

				col.rgb *= lighting;
				col.rgb = lerp(col.rgb, bgcol, 1.0 - exp(-0.003*t*t)); //para ter um falloff value porque fica cada vez mais denso

				col.a *= 0.5; //pequeno ajuste
				col.rgb *= col.a;

				return sum + col * (1.0 - sum.a);
			}

#define NOISEPROC(N,P)  1.75* N * saturate((_MaxHeight - P.y)/_FadeDist)

			float map1(float3 q) {
				float3 p = q;
				float f; //é acumlação de noise
				f = 0.5 * noise3d(q);

				q *= 2.5;
				f += 0.25 * noise3d(q);

				return NOISEPROC(f, p);
			}


#define MARCH(steps, noiseMap, cameraPos, viewDir, bgcol, sum, depth, t) { \
                for (int i = 0; i < steps  + 1; i++) \
                { \
                    if(t > depth) \
                        break; \
                    float3 pos = cameraPos + t * viewDir; \
                    if (pos.y < _MinHeight || pos.y > _MaxHeight || sum.a > 0.99) \
                    {\
                        t += max(0.1, 0.02*t); \
                        continue; \
                    }\
                    \
                    float density = noiseMap(pos); \
                    if (density > 0.01) \
                    { \
                        float diffuse = clamp((density - noiseMap(pos + 0.3 * _SunDir)) / 0.6, 0.0, 1.0);\
                        sum = integrate(sum, diffuse, density, bgcol, t); \
                    } \
                    t += max(0.1, 0.02 * t); \
                } \
            } 


			fixed4 raymarch(float3 cameraPos, float3 viewDir, fixed4 bgcol, float depth) {

				fixed4 col = fixed4(0, 0, 0, 0); //O que vamos retornar
				float ct = 0; //Contador de Steps 


				MARCH(_Steps, map1, cameraPos, viewDir, bgcol, col, depth /*_Time.r*/, ct);

				return clamp(col, 0.0, 1.0);


				return(1, 1, 1, 1);
			}



            v2f vert (appdata v)
            {
				v2f o;

				float4 wPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.view = wPos.xyz - _WorldSpaceCameraPos;
				o.projPos = ComputeScreenPos(o.pos);
				return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float depth = 1;

			//Aqui podemos usar a abordagem com sampler2D _CameraDepthTexture aka fogShader
			depth *= length(i.view);
			fixed4 col = fixed4(1, 1, 1, 0);

			fixed4 clouds = raymarch(_WorldSpaceCameraPos, normalize(i.view) * _StepScale, col, depth);
			fixed3 mixedColor = (col * (1 - clouds.a) + clouds.rgb) * _Time;

			return fixed4(mixedColor, clouds.a);
            }
            ENDCG
        }
    }
}
