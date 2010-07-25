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
module opencl.platform;

public import opencl.c.cl;
import opencl.device;
import opencl.error;
import opencl.wrapper;

alias CLObjectCollection!(cl_platform_id) CLPlatforms;

//! Platform class
class CLPlatform : CLWrapper!(cl_platform_id, clGetPlatformInfo)
{
public:
	/// constructor
	this(cl_platform_id platform)
	{
		_object = platform;
	}
	
	/// get the platform name
	string name()
	{
		 return getStringInfo(CL_PLATFORM_NAME);
	}
	
	/// get platform vendor
	string vendor()
	{
		 return getStringInfo(CL_PLATFORM_VENDOR);
	}

	/// get platform version
	string clversion()
	{
		 return getStringInfo(CL_PLATFORM_VERSION);
	}

	/// get platform profile
	string profile()
	{
		 return getStringInfo(CL_PLATFORM_PROFILE);
	}

	/// get platform extensions
	string extensions()
	{
		 return getStringInfo(CL_PLATFORM_EXTENSIONS);
	}
	
	/// returns a list of all devices available on the platform matching deviceType
	auto getDevices(cl_device_type deviceType)
	{
		cl_uint numDevices;
		cl_int res;
		
		// get number of devices
		res = clGetDeviceIDs(_object, deviceType, 0, null, &numDevices);
		switch(res)
		{
			case CL_SUCCESS:
				break;
			case CL_INVALID_PLATFORM:
				throw new CLInvalidPlatformException();
				break;
			case CL_INVALID_DEVICE_TYPE:
				throw new CLInvalidDeviceTypeException("There's no such device type");
				break;
			case CL_DEVICE_NOT_FOUND:
				throw new CLDeviceNotFoundException("Couldn't find an OpenCL device matching the given type");
				break;
			default:
				throw new CLException(res, "unexpected error while getting device count");
		}
			
		// get device IDs
		auto deviceIDs = new cl_device_id[numDevices];
		res = clGetDeviceIDs(_object, deviceType, deviceIDs.length, deviceIDs.ptr, null);
		if(res != CL_SUCCESS)
			throw new CLException(res);
		
		// create CLDevice array
		return new CLDevices(deviceIDs);
	}
	
	/// returns a list of all devices
	auto allDevices()	{return getDevices(CL_DEVICE_TYPE_ALL);}
	
	/// returns a list of all CPU devices
	auto cpuDevices()	{return getDevices(CL_DEVICE_TYPE_CPU);}
	
	/// returns a list of all GPU devices
	auto gpuDevices()	{return getDevices(CL_DEVICE_TYPE_GPU);}
	
	/// returns a list of all accelerator devices
	auto accelDevices() {return getDevices(CL_DEVICE_TYPE_ACCELERATOR);}
	
	/// get an array of all available platforms
	static CLPlatforms getPlatforms()
	{
		cl_uint numPlatforms;
		cl_int res;
		
		// get number of platforms
		res = clGetPlatformIDs(0, null, &numPlatforms);
		if(res != CL_SUCCESS)
			throw new CLInvalidValueException();
			
		// get platform IDs
		auto platformIDs = new cl_platform_id[numPlatforms];
		res = clGetPlatformIDs(platformIDs.length, platformIDs.ptr, null);
		if(res != CL_SUCCESS)
			throw new CLInvalidValueException();
		
		return new CLPlatforms(platformIDs);
	}
}