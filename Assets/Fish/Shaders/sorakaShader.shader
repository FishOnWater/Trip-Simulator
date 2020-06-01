Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _SorakaTex1("Soraka 1", 2D) = "white"{}
        _SorakaTex2("Soraka 2", 2D) = "white"{}
        _SorakaTex3("Soraka 3", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _SorakaTex1;
        sampler2D _SorakaTex2;
        sampler2D _SorakaTex3;

        struct Input
        {
            float2 uv_SorakaTex1;
            float2 uv_SorakaTex2;
            float2 uv_SorakaTex3;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 soraka1 = tex2D(_SorakaTex1, IN.uv_SorakaTex1);
            fixed4 soraka2 = tex2D(_SorakaTex2, IN.uv_SorakaTex2);
            fixed4 soraka3 = tex2D(_SorakaTex3, IN.uv_SorakaTex3);

            float timeValue = _Time;

            if (timeValue % 3 == 0) 
                o.Albedo = soraka1.rgba;
            else if (timeValue % 3 == 1) 
                o.Albedo = soraka2.rgba;
            else if(timeValue % 3 == 2)
                o.Albedo = soraka3.rgba;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
