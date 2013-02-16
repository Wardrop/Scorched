
Error Filters
-------------

Error filters are processed like regular filters, except they're called whenever an exception occurs. If an error filter returns false, it's assumed to be unhandled, and the next error filter is called. This continues until one of the following is true, 1) an error filter returns true, in which case the exception is assumed to be handled, 2) an error filter raises an exception itself, or 3) there are no more error handlers defined on the current controller, in which case the exception is re-raised.