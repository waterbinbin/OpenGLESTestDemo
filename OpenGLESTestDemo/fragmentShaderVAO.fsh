//OpenGL ES 3.0

#version 300 es

precision mediump float;
in vec4 v_color;
out vec4 o_fragColor;

void main()
{
    o_fragColor = v_color;
}

//OpenGL ES 2.0

//precision mediump float;
//varying vec4 v_color;
//
//void main()
//{
//    gl_FragColor = v_color;
//}


