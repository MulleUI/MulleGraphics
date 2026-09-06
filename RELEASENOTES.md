## 0.8.0




feature: add factory animation APIs and rename animation constructor

* new `CABasicAnimation+CGColor animationWithProperty:` factory as the recommended way to build color animations **BREAKING**: `CGPaint(CAAnimation) createAnimationFrom:` renamed to `animationFrom:`
* updated demo and test programs to use the new factory and layouter APIs


### 0.7.56

Various small improvements
