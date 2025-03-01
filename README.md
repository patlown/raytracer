### build

```zig build run```

### best looking renders so far (03-01-2025)

![5k_sphere_shadows](src/render/5k_sphere_shadows.png)


### dev log

**03-01-2025**
- got lazy doing this devlog, need to start back up again
- we can now parse an input file and render a scene, uses .pat file foramt, will add the allowable syntax and semantics at some point
  somewhere in this project
- have two major goals to work on next
  - handle more types of shapes, not just spheres.  Starting with planes and triangles.
  - introduce some acceleration structures to speed up ray tracing (spatial partitioning, bounding volumes, etc.)

**01-18-2025**
- set up basic zig project
- set up drawing a circle to stdout using 'x' and '.'

**01-19-2025**
- turned it 3d
- used llm to write sphere intersection function
- learned a lot of vector math
- need to revisit get_pixel, not sure the correct way to solve this yet but got it working

**01-23-2025**
- the math is a little annoying, used llm to help me clean up get_pixel and sphere_intersection
- need to render two spheres now, core math algorithms are done so this should be easier
