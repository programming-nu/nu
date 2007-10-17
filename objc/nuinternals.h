/*!
    @header nuinternals.h
  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
  	@discussion Internal declarations for Nu.
*/

// Execution contexts are NSMutableDictionaries that are keyed by
// symbols.  Here we define two string keys that allow us to store
// some extra information in our contexts.

// Use this key to get the symbol table from an execution context.
#define SYMBOLS_KEY @"symbols"

// Use this key to get the parent context of an execution context.
#define PARENT_KEY @"parent"