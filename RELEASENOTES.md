### 0.8.1




* add ``find_package()`` support so unrelated cmake projects can consume MulleGraphics
* add ``add_subdirectory()`` support, staging public headers for embedded builds
* propagate force-link (whole-archive) requirements of static initializer libraries to consumers
* embed a UTF-8 active code page manifest in Windows executables

## 0.8.0




feature: add factory animation APIs and rename animation constructor

* new `CABasicAnimation+CGColor animationWithProperty:` factory as the recommended way to build color animations **BREAKING**: `CGPaint(CAAnimation) createAnimationFrom:` renamed to `animationFrom:`
* updated demo and test programs to use the new factory and layouter APIs


### 0.7.56

Various small improvements
