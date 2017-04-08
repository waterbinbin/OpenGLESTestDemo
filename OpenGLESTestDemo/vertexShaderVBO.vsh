//OpenGL ES 3.0

#version 300 es

layout(location = 0) in vec4 a_position;
layout(location = 1) in vec4 a_color;
uniform float u_offset;
out vec4 v_color;

void main()
{
    v_color = a_color;
    gl_Position = a_position;
    gl_Position.x += u_offset;
}

//OpenGL ES 2.0

//attribute vec4 a_position;
//attribute vec4 a_color;
//uniform float u_offset;
//varying vec4 v_color;
//
//void main()
//{
//    v_color = a_color;
//    gl_Position = a_position;
//    gl_Position.x += u_offset;
//}

