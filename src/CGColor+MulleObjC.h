#import "import.h"


static inline void   MulleObjectSetCGColor( id obj, SEL sel, CGColor color)
{
   mulle_metaabi_union_void_return( struct { CGColor color; })  param;

   param.p.color = color;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
}


static inline CGColor   MulleObjectGetCGColor( id obj, SEL sel)
{
   mulle_metaabi_union_void_parameter( struct { CGColor color; })  param;

   mulle_objc_object_call( obj, (mulle_objc_methodid_t) sel, &param);
   return( param.r.color);
}
