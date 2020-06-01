Shader "Unlit/messageShader"
{
    Properties
    {
        //_PlainColour("Plain Colour", Color) = (1,1,1,0)
        _TestTex("testing", 2D) = "white"{}
        _HiddenMessage("Message", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM   
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uvH : TEXCOORD0;
                float2 uvT : TEXCOORD1;
            };

            struct v2f
            {
                float2 uvH : TEXCOORD0;
                float2 uvT : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float showMe : TEXCOORD2;
            };

            //fixed4 _PlainColour;

            sampler2D _HiddenMessage;
            float4 _HiddenMessage_ST;
            sampler2D _TestTex;
            float4 _TestTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uvT = TRANSFORM_TEX(v.uvT, _TestTex);
                o.uvH = TRANSFORM_TEX(v.uvH, _HiddenMessage);
                o.showMe = length(pow(WorldSpaceViewDir(v.vertex), 15));

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 pColour = _PlainColour;

                
                fixed4 hMessage = tex2D(_HiddenMessage, i.uvH);
                fixed4 test = tex2D(_TestTex, i.uvT);

                test = test - i.showMe < 0 ? test : hMessage;
                //pColour = pColour < 0 ? pColour : hMessage;

                return test;
                //return pColour;
            }
            ENDCG
        }
    }
}
