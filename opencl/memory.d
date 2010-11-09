/*
cl4d - object-oriented wrapper for the OpenCL C API v1.1
written in the D programming language

Copyright (C) 2009-2010 Andreas Hollandt

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module opencl.memory;

import opencl.c.cl;
import opencl.context;
import opencl.error;
import opencl.wrapper;

//! buffer class
abstract class CLMemory : CLWrapper!(cl_mem, clGetMemObjectInfo)
{
private:

protected:
	//!
	this(cl_mem buffer)
	{
		super(buffer);
	}
	
public:
	/**
	 *	registers a user callback function with a memory object
	 *	Each call registers the specified user callback function on a callback stack associated with memobj.
	 *	The registered user callback functions are called in the reverse order in which they were registered.
	 *	The user callback functions are called and then the memory object's resources are freed and the memory object is deleted.
	 *
	 *	This provides a mechanism to be notified when the memory referenced by host_ptr, specified when the memory object was created
	 *	and used as the storage bits for the memory object, can be reused or freed
	 */
	void setDestructorCallback(mem_notify_fn fpNotify, void* userData = null)
	{
		cl_int res = clSetMemObjectDestructorCallback(this.getObject(), fpNotify, userData);
		
		mixin(exceptionHandling(
			["CL_INVALID_MEM_OBJECT",	""],
			["CL_INVALID_VALUE",		"fpNotify is null"],
			["CL_OUT_OF_RESOURCES",		""],
			["CL_OUT_OF_HOST_MEMORY",	""]
		));
	}
	
	//! ditto
	@property void destructorCallback(mem_notify_fn fpNotify)
	{
		setDestructorCallback(fpNotify);
	}
	
	@property CLContext context()
	{
		return null;
		// TODO
	}
	/+
	@property
	{
		bool isBuffer()
		{
			auto type = getInfo!cl_mem_object_type(CL_MEM_TYPE);
			switch(type)
			{
				case CL_MEM_OBJECT_BUFFER:
				
				break;

				default:
				break;
			}
		}
	}+/
}