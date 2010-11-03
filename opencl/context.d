/*
cl4d - object-oriented wrapper for the OpenCL C API v1.1 revision 33
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
module opencl.context;

import opencl.c.cl;
import opencl.device;
import opencl.error;
import opencl.platform;
import opencl.program;
import opencl.wrapper;

/**
 * context class
 * Contexts are used by the OpenCL runtime for managing objects such as command-queues, memory,
 * program and kernel objects and for executing kernels on one or more devices specified in the context.
 */
class CLContext : CLWrapper!(cl_context, clGetContextInfo)
{
private:
	CLPlatform	_platform;
	CLDevices	_devices;

public:
	//! TODO: check reference counting
	this(cl_context context)
	{
		super(context);
	}
	
	/// creates an OpenCL context with the given devices
	this(CLDevices devices)
	{
		cl_int res;
		
		// TODO: add platform_id verification and
		auto deviceIDs = devices.getObjArray();

		// TODO: user notification function
		_object = clCreateContext(null, deviceIDs.length, deviceIDs.ptr, null, null, &res);
		if(!_object)
			mixin(exceptionHandling(
				["CL_INVALID_PLATFORM",		"no valid platform could be selected for context creation"],
				["CL_INVALID_VALUE",		"devices array has length 0 or a null pointer"],
				["CL_INVALID_DEVICE",		"devices contains an invalid device or are not associated with the specified platfor"],
				["CL_DEVICE_NOT_AVAILABLE",	"a device is currently not available even though the device was returned by getDevices"],
				["CL_OUT_OF_HOST_MEMORY",	""]
			));
	}
	
	/// create a context from all available devices
	this()
	{
		cl_int res;
		_object = clCreateContextFromType(null, CL_DEVICE_TYPE_ALL, null, null, &res);
		
		mixin(exceptionHandling(
			["CL_INVALID_PLATFORM",		"no platform could be selected"],
			["CL_INVALID_VALUE",		"internal invalid value error"],
			["CL_DEVICE_NOT_AVAILABLE",	"no devices currently available"],
			["CL_DEVICE_NOT_FOUND",		"no devices were found"],
			["CL_OUT_OF_HOST_MEMORY",	""]
		));
	}
	
	~this()
	{
		release();
	}
	
	/// increments the context reference count
	CLContext retain()
	{
		cl_int res;
		res = clRetainContext(_object);
		if(res != CL_SUCCESS)
			throw new CLInvalidContextException("internal context object is not a valid OpenCL context");
		
		return this;
	}
	
	/// decrements the context reference count
	void release()
	{
		cl_int res;
		res = clReleaseContext(_object);
		if(res != CL_SUCCESS)
			throw new CLInvalidContextException("internal context object is not a valid OpenCL context");
	}
	
	CLProgram createProgram(string sourceCode)
	{
		return new CLProgram(this, sourceCode);
	}
}

/**
 * a context using all available GPU devices
 */
class CLGPUContext : CLContext
{
	this()
	{
		cl_int res;
		_object = clCreateContextFromType(null, CL_DEVICE_TYPE_GPU, null, null, &res);
		
		switch(res)
		{
			case CL_SUCCESS:
				break;
			case CL_INVALID_PLATFORM:
				throw new CLInvalidPlatformException("no platform could be selected");
				break;
			case CL_INVALID_VALUE:
				throw new CLInvalidValueException("internal invalid value error");
				break;
			case CL_DEVICE_NOT_AVAILABLE:
				throw new CLDeviceNotAvailableException("no GPU devices currently available");
				break;
			case CL_DEVICE_NOT_FOUND:
				throw new CLDeviceNotFoundException("no GPU devices were found");
				break;
			case CL_OUT_OF_HOST_MEMORY:
				throw new CLOutOfHostMemoryException();
				break;
			default:
				throw new CLUnrecognizedException(res);
		}
	}
}

/**
* a context using all available CPU devices
*/
class CLCPUContext : CLContext
{
	this()
	{
		cl_int res;
		_object = clCreateContextFromType(null, CL_DEVICE_TYPE_CPU, null, null, &res);
		
		switch(res)
		{
			case CL_SUCCESS:
				break;
			case CL_INVALID_PLATFORM:
				throw new CLInvalidPlatformException("no platform could be selected");
				break;
			case CL_INVALID_VALUE:
				throw new CLInvalidValueException("internal invalid value error");
				break;
			case CL_DEVICE_NOT_AVAILABLE:
				throw new CLDeviceNotAvailableException("no CPU devices currently available");
				break;
			case CL_DEVICE_NOT_FOUND:
				throw new CLDeviceNotFoundException("no CPU devices were found");
				break;
			case CL_OUT_OF_HOST_MEMORY:
				throw new CLOutOfHostMemoryException();
				break;
			default:
				throw new CLUnrecognizedException(res);
		}
	}
}

/**
* a context using all available accelerator devices
*/
class CLAccelContext : CLContext
{
	this()
	{
		cl_int res;
		_object = clCreateContextFromType(null, CL_DEVICE_TYPE_ACCELERATOR, null, null, &res);
		
		switch(res)
		{
			case CL_SUCCESS:
				break;
			case CL_INVALID_PLATFORM:
				throw new CLInvalidPlatformException("no platform could be selected");
				break;
			case CL_INVALID_VALUE:
				throw new CLInvalidValueException("internal invalid value error");
				break;
			case CL_DEVICE_NOT_AVAILABLE:
				throw new CLDeviceNotAvailableException("no accelerator devices currently available");
				break;
			case CL_DEVICE_NOT_FOUND:
				throw new CLDeviceNotFoundException("no accelerator devices were found");
				break;
			case CL_OUT_OF_HOST_MEMORY:
				throw new CLOutOfHostMemoryException();
				break;
			default:
				throw new CLUnrecognizedException(res);
		}
	}
}

/**
* a context using all available default devices
*/
class CLDefaultContext : CLContext
{
	this()
	{
		cl_int res;
		_object = clCreateContextFromType(null, CL_DEVICE_TYPE_DEFAULT, null, null, &res);
		
		switch(res)
		{
			case CL_SUCCESS:
				break;
			case CL_INVALID_PLATFORM:
				throw new CLInvalidPlatformException("no platform could be selected");
				break;
			case CL_INVALID_VALUE:
				throw new CLInvalidValueException("internal invalid value error");
				break;
			case CL_DEVICE_NOT_AVAILABLE:
				throw new CLDeviceNotAvailableException("no devices currently available");
				break;
			case CL_DEVICE_NOT_FOUND:
				throw new CLDeviceNotFoundException("no devices were found");
				break;
			case CL_OUT_OF_HOST_MEMORY:
				throw new CLOutOfHostMemoryException();
				break;
			default:
				throw new CLUnrecognizedException(res);
		}
	}
}