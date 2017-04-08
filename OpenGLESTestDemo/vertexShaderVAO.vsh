//OpenGL ES 3.0

#version 300 es

layout(location = 0) in vec4 a_position;
layout(location = 1) in vec4 a_color;
out vec4 v_color;

void main()
{
    v_color = a_color;
    gl_Position = a_position;
}

//OpenGL ES 2.0

//attribute vec4 a_position;
//attribute vec4 a_color;
//varying vec4 v_color;
//
//void main()
//{
//    v_color = a_color;
//    gl_Position = a_position;
//}

