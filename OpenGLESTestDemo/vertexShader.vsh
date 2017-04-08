//OpenGL ES 3.0

#version 300 es

layout(location = 0) in vec4 vPosition;

void main()
{
    gl_Position = vPosition;
}

//OpenGL ES 2.0

//attribute vec4 vPosition;
//
//void main()
//{
//    gl_Position = vPosition;
//}
