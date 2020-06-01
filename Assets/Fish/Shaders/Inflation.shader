Shader "Custom/Inflation"
{
    Properties
    {

        _MainTex("Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump"{}
        _ScaleUV("Scale", Range(-10,20)) = 1
    }
        SubShader
        {
            Tags{ "Queue" = "Transparent" }
            GrabPass{}
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
                float4 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 uvgrab : TEXCOORD1; //Vamos buscar estas uvs específicas em vez de usarmos todas
                float4 uvbump : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float4 normal : NORMAL;
            };

            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize; //_TexelSize é reservado
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _ScaleUV;
            
            

            // uniform float Gradient[20][20][2];

            // float dotGridGradient(int ix, int iy, float x, float y) {
                
            //     // Precomputed (or otherwise) gradient vectors at each grid node
            //     // Compute the distance vector
            //     float dx = x - (float)ix;
            //     float dy = y - (float)iy;
    
            //     // Compute the dot-product
            //     return (dx*Gradient[iy][ix][0] + dy*Gradient[iy][ix][1]);
            // }

            // float2 perlin(float x, float y){
            //     int x0 = (int)x;
            //     int x1 = x0 + 1;
            //     int y0 = (int)y;
            //     int y1 = y0 + 1;

            //     float sx = x - (float)x0;
            //     float sy = y - (float)y0;

            //     float n0, n1, ix0, ix1, value;

            //     n0 = dotGridGradient(x0, y0, x, y);
            //     n1 = dotGridGradient(x1, y0, x, y);
            //     ix0 = lerp(n0, n1, sx);

            //     n0 = dotGridGradient(x0, y1, x, y);
            //     n1 = dotGridGradient(x1, y1, x, y);
            //     ix1 = lerp(n0, n1, sx);

            //     // value = lerp(ix0, ix1, sy);
            //     return (ix0, ix1);
            // }

            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(100,100)))*1.0);
        //          return fract(sin(dot(st.xy,
        //                  vec2(-0.920,-0.870)))*
        // 504653.5453123);
            }

            v2f vert(appdata v)
            {
                v2f o;
                
                float n0,n1,ix0,ix1;

                float4 vectors = v.normal;
                // vectors.x = random(v.uv);
                // vectors.y = random(v.uv);
                
                int x0 = (int)vectors.x;
                int x1 = x0 + 1;
                int y0 = (int)vectors.z;
                int y1 = y0 + 1;

                float sx = vectors.x - (float)x0;
                float sy = vectors.z - (float)y0;

                n0 = dot(vectors.x,vectors.z);
                n1 = dot(vectors.x+1,vectors.z);
                ix0 = lerp(n0, n1, sx);

                n0 = dot(vectors.x,vectors.z+1);
                n1 = dot(vectors.x+1,vectors.z+1);
                ix1 = lerp(n0, n1, sy);

                vectors = float4 (ix0,ix1,1,1);
                
                o.normal = v.normal;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // o.uv.xy = o.uv.x, o.uv.y*cos(2);
                fixed a = 0.5;
                // float2x2 rotationMatrix = (cos(3.14/2), -sin(3.14/2)   ,sin(3.14/2),cos(3.14/2));
                o.uvgrab.xy = (float2(o.vertex.x, -o.vertex.y) + o.vertex.w) * a;
                o.uvgrab.xy += float2(o.vertex.x, -o.vertex.y)*_ScaleUV;

                // if (_ScaleUV < -0.5){
                //     o.uvgrab.xy  =  mul(o.uvgrab.xy,rotationMatrix);
                // }
                o.uvgrab.xy += vectors.xy;
                // mul(float2(o.vertex.x, -o.vertex.y),rotationMatrix)
                // o.uvgrab.xy +=  float2(o.vertex.x, -o.vertex.y)*cos(2);//
                o.uvgrab.zw = o.vertex.zw;
            
                // o.uvgrab = float4(o.vertex.x*_ScaleUV,-o.vertex.y*_ScaleUV ,o.vertex.z,o.vertex.w);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {

                if(i.uvgrab.w == 1){
                    clip(-1);
                }
                float4 uvDistortion;
                fixed4 colP = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.uvgrab)); //*float4(0.9,0.9,0.9,1); //<- efeito tint no vidro
                fixed4 perlinNoise = (.1,.1,.1,1);
                // float n0,n1,ix0,ix1;

                // float4 vectors = i.normal;
                // // for float x in vector.x {
                // //     x = (((rand() % 10) + 1)/10);
                // // }
                // vectors.x = random(i.uv);
                // vectors.z = random(i.uv);
                
                //  int x0 = (int)vectors.x;
                //  int x1 = x0 + 1;
                //  int y0 = (int)vectors.z;
                //  int y1 = y0 + 1;

                // float sx = vectors.x - (float)x0;
                // float sy = vectors.z - (float)y0;

                // n0 = dot(vectors.x,vectors.z);
                // n1 = dot(vectors.x+1,vectors.z);
                // ix0 = lerp(n0, n1, sx);

                // n0 = dot(vectors.x,vectors.z+1);
                // n1 = dot(vectors.x+1,vectors.z+1);
                // ix1 = lerp(n0, n1, sy);

                // vectors = float4 (ix0,1,ix1,1);
                fixed4 tint = tex2D(_MainTex, i.uv);
                fixed4 col = colP * tint;
                // return vectors;
                // return perlinNoise * float4(ix0,ix1,0,1);
                return col;
            }
            ENDCG
        }
    }
}