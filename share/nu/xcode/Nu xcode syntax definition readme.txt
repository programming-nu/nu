Nu syntax files for xcode
=========================

Here's a very minimal syntax definition for xcode.  The main point of this is that it allows code folding. :-)   Any s-expression can be folded.

I haven't bothered to define a lot of keywords.

Copy these files (except for this readme) to "/Developer/Library/Xcode/Specifications" and restart xcode.  In addition to restarting xcode, you may have to tell it to use these new syntax defs for your nu files: do that by choosing the Information inspector on any nu file in xcode, and selecting "sourcecode.nu" from one of the drop-down menus in the inspector.

The format of these files is an undocumented black art. :-(  The only hints I've been able to find are by looking at other syntax files, which I found by searching the web for "xcsynspec".

Jason Grossman 2009