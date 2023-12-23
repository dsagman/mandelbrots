import OpenGL.GL as gl
import OpenGL.GLUT as glut
from PIL import Image
import time

def load_shader(shader_file):
    with open(shader_file, 'r') as file:
        shader_source = file.read()
    return shader_source

def setup_shader():
    # Create a shader program
    program = gl.glCreateProgram()

    # Load and compile the fragment shader
    shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER)
    gl.glShaderSource(shader, load_shader("./src/mandelbrot.frag"))
    gl.glCompileShader(shader)

    # Attach shader to program and link
    gl.glAttachShader(program, shader)
    gl.glLinkProgram(program)

    return program

def draw_mandelbrot_set(width, height, program):
    # Setup viewport and orthographic projection
    gl.glViewport(0, 0, width, height)
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glLoadIdentity()
    gl.glOrtho(0, width, 0, height, -1, 1)

    # Clear screen
    gl.glClear(gl.GL_COLOR_BUFFER_BIT)

    # Use the shader program
    gl.glUseProgram(program)

    # Set uniforms
    gl.glUniform1f(gl.glGetUniformLocation(program, "width"), width)
    gl.glUniform1f(gl.glGetUniformLocation(program, "height"), height)
    gl.glUniform1f(gl.glGetUniformLocation(program, "rmin"), RE_START)
    gl.glUniform1f(gl.glGetUniformLocation(program, "rmax"), RE_END)
    gl.glUniform1f(gl.glGetUniformLocation(program, "imin"), IM_START)
    gl.glUniform1f(gl.glGetUniformLocation(program, "imax"), IM_END)
    gl.glUniform1i(gl.glGetUniformLocation(program, "max_iter"), MAX_ITER)

    # Draw a rectangle covering the viewport
    gl.glBegin(gl.GL_QUADS)
    gl.glVertex2f(0, 0)
    gl.glVertex2f(width, 0)
    gl.glVertex2f(width, height)
    gl.glVertex2f(0, height)
    gl.glEnd()

    # Flush drawing commands
    gl.glFlush()

def save_image_from_texture(width, height, filename):
    # Read the pixels from the framebuffer
    pixels = gl.glReadPixels(0, 0, width, height, gl.GL_RGB, gl.GL_UNSIGNED_BYTE)

    # Convert to an image and save
    image = Image.frombytes("RGB", (width, height), pixels)
    image = image.transpose(Image.FLIP_TOP_BOTTOM)
    image.save(filename)

def display():

    # Draw Mandelbrot set
    draw_mandelbrot_set(width, height, shader_program)

    # Swap buffers for smooth animation
    glut.glutSwapBuffers()

def main():
    global shader_program, width, height, RE_START, RE_END, IM_START, IM_END, MAX_ITER
    # Image size
    # width, height = 640, 350
    width, height = 1920, 1080

    # Bounds for the Mandelbrot set
    RE_START = -0.74612
    RE_END = -0.74427
    IM_START = 0.11196
    IM_END = 0.11339
    print(f"Center point is, {(RE_START + RE_END) / 2}+{(IM_START + IM_END) / 2}i")

    # Max iterations
    MAX_ITER = 1000000

    # Initialize GLUT
    glut.glutInit()
    glut.glutInitDisplayMode(glut.GLUT_SINGLE | glut.GLUT_RGB)
    glut.glutInitWindowSize(width, height)
    glut.glutCreateWindow("Mandelbrot Set")

    print("Starting calculations...")
    start_time = time.time()

    # Setup shader
    shader_program = setup_shader()

    # Register display callback
    glut.glutDisplayFunc(display)

    end_time = time.time()
    print(f"Image saved as 'mandelbrot_pypy.png' (Calculation time: {end_time - start_time:.2f} seconds)")

    # Enter the GLUT main loop
    glut.glutMainLoop()

    # # Save image
    # save_image_from_texture(width, height, 'mandelbrot_gpu.png')

if __name__ == "__main__":
    

    main()

