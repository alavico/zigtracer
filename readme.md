# Zigtracer
My implementation of [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html) in Zig. 

Here is an image of my final render:

![Render](render.png)

## To run
clone the repo, make sure you have zig version 0.13.0 and run in the root dir: 

`zig build run --summary all`

The ray tracer will output `render.ppm`

## Future Optimizations
- [ ] Take advantage of @Vector built ins (SIMD)
- [ ] Threading
- [ ] buffered writes to file
- [ ] ??? 

## Performance
Takes 1136 secs to run on my machine (~19 mins)
