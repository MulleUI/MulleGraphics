### 0.7.56

* new mulle-sde config projects style
* fix for multi-window


* emit CGContextTraceComment markers around background, border, setup, will-draw and draw phases so rendering sequences are visible in tracing/debug outputs
* unify text-layouter debug output by replacing ad-hoc logs with CATextLayerLayouterLog for consistent, configurable verbosity


feature: enhance CATextLayer editing, cursor navigation, and selection handling

* Add word-wise navigation & editing (cursorWordLeft/Right, cursorHome/End/DocHome/DocEnd, deleteWordBefore/After, selectWordAtCursor) for richer text editing.
* Track selection as a byte-range per row (selectionRange) so selection rendering and hit-testing map precisely to UTF-8 offsets.
* Improve cursor hit-testing and character-offset mapping (more accurate row detection, clamping behavior, and before/after glyph handling).
* Make layout/render more robust (reorder prepareLayoutContext, optional baseline debug overlay) and guard framebuffer access in CAAccumulationLayer.
* Minor API: CAImageLayer category now declares MulleObjCFuture conformance.



* converted all nvg drawing calls to CGContext struct-based API in library and demos
* replaced flat nvg geometry arguments with CGPoint/CGRect/CACircle structs
* updated gradient calls to void-return CGContext API (no NVGpaint)
* converted arc calls to use CAAngle/CARotation with proper normalization
* updated demo code to use CGContext text, path, and shape functions






* recoded renderInContext: for more clarity, also figured out that nvgScissorIntersect does not work for rotation, i.e. widening the scissor yikes



* uses CGBlendedPaint not for interpolation of images (and gradients with images)

* add convenience properties borderColor and backgroundColor to CGGraphicsLayer






















* death of the Mulle prefix, use CA now even for incompatible stuff

* split MulleGraphics off from MulleUI


* nach dem Fundamentalumbau mit CALayer im windowspace und der



* new demo render-png to render out a PNG file










* UITextField added

* fix UIView conversion toView
* much improved MullePopUpButton
* layer drawing methods now return a YES if transform or scissor have been affected

* MulleJS is now its own project in MulleWeb
* MulleMenu and MullePopUpButton added (rename to MulleUIMenu ...) ?


* drawImage() and rect() added

* color creation with strings
* javascript interface for nanovg
* new method setSubviews: on UIView
* new UIStackView layout MulleStackViewDistributionFillRowColumn









* CALayer now uses introspection to generate animations for observable properties

































* layoutSubviews with flexbox

* experimental yoga layouting

* add TODO list to README.md

* improved SVG rendering

* redid CALayer background drawing and border




* UIImage added. UIButton can now change its background image

* UIControl as protocolclass added

* modernized mulle-sde
* UIEvents are distributed to subviews properly
