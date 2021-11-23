//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "MulleEdgeInsets+UTF8String.h"

#import "import-private.h"


// cast this to CGRect as the code is identical ?
char   *MulleEdgeInsetsUTF8String( MulleEdgeInsets insets)
{
   auto char  *s;

   s = MulleObjC_asprintf( "%.2f %.2f %.2f %.2f",
         insets.top,
         insets.left,
         insets.bottom,
         insets.right);
   return( s);
}
