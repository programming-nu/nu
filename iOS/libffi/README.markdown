libffi for the iPhone
=

**[libffi](http://sourceware.org/libffi/)** allows calling any C-function or ObjC method at runtime.

**libffi-iphone** is a stripped down version of libffi, tailored just for the iPhone. **libffi-iphone** includes source code for both the iPhone simulator and the iPhone itself.

Calling functions
-
Works just like libffi.

Creating ffi closures, new functions created and called at runtime
-
ffi closures don't work on the iPhone, as <code>mprotect</code> is disabled.

You can however retarget existing functions if you have a function pool. See [Tim Burks' post about Nu's method pool](http://stackoverflow.com/questions/219653/ruby-on-iphone), see [JSCocoa's Burks Pool](http://github.com/parmanoir/jscocoa/blob/master/JSCocoa/iPhone/BurksPool.m) for another implementation.

To retarget an ObjC pool method, use the method's hidden <code>_cmd</code> argument (the current selector) and <code>[self class]</code>. This will tell you which method of which class is being called.

License
-
**libffi-iphone** uses **libffi**'s license.

Hey
-
Problems, questions <br/>
Patrick Geiller <br/>
[parmanoir@gmail.com](mailto:parmanoir@gmail.com)
