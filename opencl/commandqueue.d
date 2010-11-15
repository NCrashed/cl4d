/**
 *	cl4d - object-oriented wrapper for the OpenCL C API
 *	written in the D programming language
 *
 *	Copyright:
 *		(C) 2009-2010 Andreas Hollandt
 *
 *	License:
 *		see LICENSE.txt
 */
module opencl.commandqueue;

import opencl.c.cl;
import opencl.buffer;
import opencl.context;
import opencl.device;
import opencl.error;
import opencl.event;
import opencl.kernel;
import opencl.wrapper;

//!
class CLCommandQueue : CLWrapper!(cl_command_queue, clGetCommandQueueInfo)
{
protected:
	//! 
	this(cl_command_queue commandQueue)
	{
		super(commandQueue);
	}

public:
	/**
	 *	creates a command-queue on a specific device
	 *
	 *	Params:
	 *		context		=	must be a valid context
	 *		device		=	must be a device associated with context
	 *		outOfOrder	=	Determines whether the commands queued in the command-queue are executed in-order or out-oforder
	 *		profiling	=	Enable or disable profiling of commands in the command-queue
	 */
	this(CLContext context, CLDevice device, bool outOfOrder = false, bool profiling = false)
	{
		cl_int res;
		_object = clCreateCommandQueue(context.getObject(), device.getObject(), (outOfOrder ? CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE : 0) | (profiling ? CL_QUEUE_PROFILING_ENABLE : 0), &res);
		
		mixin(exceptionHandling(
			["CL_INVALID_CONTEXT",			"context is not a valid context"],
			["CL_INVALID_DEVICE",			"device is not a valid device or is not associated with context"],
			["CL_INVALID_VALUE",			"values specified in properties are not valid"],
			["CL_INVALID_QUEUE_PROPERTIES",	"values specified in properties are valid but are not supported by the device"],
			["CL_OUT_OF_RESOURCES",			""],
			["CL_OUT_OF_HOST_MEMORY",		""]
		));
	}
	
	/**
	 *	issues all previously queued OpenCL commands to the device associated with command_queue.
	 *	flush only guarantees that all queued commands get issued to the appropriate device.
	 *	There is no guarantee that they will be complete after flush returns.
	 *
	 *	Any blocking commands queued in a command-queue and clReleaseCommandQueue perform
	 *	an implicit flush of the command-queue.
	 *
	 *	To use event objects that refer to commands enqueued in a command-queue as event objects to
	 *	wait on by commands enqueued in a different command-queue, the application must call a
	 *	flush or any blocking commands that perform an implicit flush of the command-queue where
	 *	the commands that refer to these event objects are enqueued.
	 */
	void flush()
	{
		cl_int res = clFlush(getObject());
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",	""],
			["CL_OUT_OF_RESOURCES",			""],
			["CL_OUT_OF_HOST_MEMORY",		""]
		));
	}
	
	/**
	 *	blocks until all previously queued OpenCL commands in command_queue are issued to the
	 *	associated device and have completed. clFinish does not return until all queued commands in
	 *	command_queue have been processed and completed. clFinish is also a synchronization point.
	 */
	void finish()
	{
		cl_int res = clFinish(getObject());
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",	""],
			["CL_OUT_OF_RESOURCES",			""],
			["CL_OUT_OF_HOST_MEMORY",		""]
		));
	}
	
	CLEvent enqueueNDRangeKernel(CLKernel kernel, ref NDRange offset, ref NDRange global, ref NDRange local,
							CLEvents waitlist = null) const
	{
		cl_event event;
		cl_int res = clEnqueueNDRangeKernel(_object, kernel.getObject(), global.dimensions, offset.ptr, global.ptr, local.ptr, waitlist.length, waitlist.ptr, &event);
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",	""],
			["CL_INVALID_PROGRAM_EXECUTABLE","there is no successfully built program executable available for device associated with the queue"],
			["CL_INVALID_KERNEL",			""],
			["CL_INVALID_CONTEXT",			""],
			["CL_INVALID_KERNEL_ARGS",		"the kernel argument values have not been specified"],
			["CL_INVALID_WORK_DIMENSION",	""]
		));
		
		return new CLEvent(event);
	}
	
	/**
	 *	enqueue commands to read from a buffer object to host memory or write to a buffer object from host memory
	 *
	 *	the command queue and the buffer must be created with the same OpenCL context
	 *
	 *	Params:
	 *		blocking	=	if false, queues a non-blocking read/write command and returns. The contents of the buffer that ptr points to
	 *								cannot be used until the command has completed. The function returns an event
	 *								object which can be used to query the execution status of the read command. When the read
	 *								command has completed, the contents of the buffer that ptr points to can be used by the application
	 *		offset		=	is the offset in bytes in the buffer object to read from or write to
	 *		size		=	is the size in bytes of data being read or written
	 *		ptr			=	is the pointer to buffer in host memory where data is to be read into or to be written from
	 *		waitlist	=	specifies events that need to complete before this particular command can be executed
	 *						they act as synchronization points. The context associated with events in waitlist and the queue must be the same
	 *
	 *	Returns:
	 *		an event object that identifies this particular read / write command and can be used to query or queue a wait for this particular command to complete
	 */
	private CLEvent enqueueReadWriteBuffer(alias func, PtrType)(CLBuffer buffer, cl_bool blocking, size_t offset, size_t size, PtrType ptr, CLEvents waitlist = null)
	in
	{
		assert(ptr !is null);
	}
	body
	{
		cl_event event;
		cl_int res = func (_object, buffer.getObject(), blocking, offset, size, ptr, waitlist.length, waitlist.ptr, &event);
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",						""],
			["CL_INVALID_CONTEXT",								"context associated with command queue and buffer or waitlist is not the same"],
			["CL_INVALID_MEM_OBJECT",							"buffer is invalid"],
			["CL_INVALID_VALUE",								"region being read/written specified by (offset, size) is out of bounds"],
			["CL_INVALID_EVENT_WAIT_LIST",						"event objects in waitlist are not valid events"],
			["CL_MISALIGNED_SUB_BUFFER_OFFSET",					"buffer is a sub-buffer object and offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"],
			["CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST",	"the read operations are blocking and the execution status of any of the events in waitlist is a negative integer value"],
			["CL_MEM_OBJECT_ALLOCATION_FAILURE",				"couldn't allocate memory for data store associated with buffer"],
			["CL_OUT_OF_RESOURCES",								""],
			["CL_OUT_OF_HOST_MEMORY",							""]
		));

		return new CLEvent(event);
	}
	alias enqueueReadWriteBuffer!(clEnqueueReadBuffer, void*) enqueueReadBuffer; //! ditto
	alias enqueueReadWriteBuffer!(clEnqueueWriteBuffer, const void*) enqueueWriteBuffer; //! ditto
	
	/**
	 *	enqueue commands to read a 2D or 3D rectangular region from a buffer object to host memory or write a 2D or 3D rectangular region to a buffer object from host memory
	 *
	 *	Also see enqueueReadWriteBuffer and OpenCL specs NOTE
	 *
	 *	Params:
	 *	    bufferOrigin	=	defines the (x, y, z) offset in the memory region associated with buffer. For a 2D rectangle region, the z value given by buffer_origin[2] should be 0. The offset in bytes is
	 *							computed as buffer_origin[2] * buffer_slice_pitch + buffer_origin[1] * buffer_row_pitch + buffer_origin[0]
	 *	    hostOrigin		=	the (x, y, z) offset in the memory region pointed to by ptr. For a 2D rectangle region, the z value given by host_origin[2] should be 0. The offset in bytes is computed as
	 *							host_origin[2] * host_slice_pitch + host_origin[1] * host_row_pitch + host_origin[0].
	 *	    region			=	the (width, height, depth) in bytes of the 2D or 3D rectangle being read or written. For a 2D rectangle copy, the depth value given by region[2] should be 1
	 *	    bufferRowPitch	=	the length of each row in bytes to be used for the memory region associated with buffer. If buffer_row_pitch is 0, buffer_row_pitch is computed as region[0]
	 *	    bufferSlicePitch=	the length of each 2D slice in bytes to be used for the memory region associated with buffer. If buffer_slice_pitch is 0, buffer_slice_pitch is computed as region[1] * buffer_row_pitch
	 *	    hostRowPitch	=	the length of each row in bytes to be used for the memory region pointed to by ptr. If host_row_pitch is 0, host_row_pitch is computed as region[0]
	 *	    hostSlicePitch	=	the length of each 2D slice in bytes to be used for the memory region pointed to by ptr. If host_slice_pitch is 0, host_slice_pitch is computed as region[1] * host_row_pitch
	 *	    ptr				=	pointer to buffer in host memory where data is to be read into or to be written from
	 *
	 *	TODO: add assertions that buffer origin etc. is correct in respect to CLBuffer isImage2D etc. see above notes
	 */
	private void enqueueReadWriteBufferRect(alias func, PtrType)(CLBuffer buffer, cl_bool blocking, const size_t[3] bufferOrigin, const size_t[3] hostOrigin, const size_t[3] region,
	                                                             PtrType ptr, CLEvents waitlist = null, size_t bufferRowPitch = 0, size_t bufferSlicePitch = 0, size_t hostRowPitch = 0, size_t hostSlicePitch = 0)
	in
	{
		assert(ptr !is null);
		assert(region[0] != 0u && region[1] != 0u && region[2] != 0u);
		if (bufferRowPitch > 0)
			assert(bufferRowPitch >= region[0]);
		if (hostRowPitch > 0)
			assert(hostRowPitch >= region[0]);
		if (bufferSlicePitch > 0)
			assert(bufferSlicePitch >= region[1] * bufferRowPitch);
		if (hostSlicePitch > 0)
			assert(hostSlicePitch >= region[1] * hostRowPitch);
	}
	body
	{
		// TODO: leave the default pitch values as 0 and let OpenCL compute or set default values as region[0]? etc. see method documentation
		cl_event event;
		cl_int res = func(_object, buffer.getObject(), blocking, bufferOrigin.ptr, hostOrigin.ptr, region.ptr, bufferRowPitch, bufferSlicePitch, hostRowPitch, hostSlicePitch, ptr, waitlist.length, waitlist.ptr, &event);
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",						""],
			["CL_INVALID_CONTEXT",								"context associated with command queue and buffer or waitlist is not the same"],
			["CL_INVALID_MEM_OBJECT",							"buffer is invalid"],
			["CL_INVALID_VALUE",								"region being read/written specified by (bufferOrigin, region) is out of bounds or pitch values are invalid"],
			["CL_INVALID_EVENT_WAIT_LIST",						"event objects in waitlist are not valid events"],
			["CL_MISALIGNED_SUB_BUFFER_OFFSET",					"buffer is a sub-buffer object and offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"],
			["CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST",	"the read operations are blocking and the execution status of any of the events in waitlist is a negative integer value"],
			["CL_MEM_OBJECT_ALLOCATION_FAILURE",				"couldn't allocate memory for data store associated with buffer"],
			["CL_OUT_OF_RESOURCES",								""],
			["CL_OUT_OF_HOST_MEMORY",							""]
		));

		return new CLEvent(event);

	}
	alias enqueueReadWriteBufferRect!(clEnqueueReadBufferRect, void*) enqueueReadBufferRect; //! ditto
	alias enqueueReadWriteBufferRect!(clEnqueueWriteBufferRect, const void*) enqueueWriteBufferRect; //! ditto
	
	/**
	 *	enqueues a command to copy a buffer object identified by srcBuffer to another buffer object identified by dstBuffer
	 *
	 *	Params:
	 *	    srcOffset	= the offset where to begin copying data from srcBuffer
	 *	    dstOffset	= the offset where to begin copying data into dstBuffer
	 *	    size		= size in bytes to copy
	 *
	 *	Returns:
	 *		an event object that identifies this particular copy command and can be used to
	 *		query or queue a wait for this particular command to complete
	 *		The event can be ignored in which case it will not be possible for the application to query the status of this command or queue a
	 *		wait for this command to complete.  clEnqueueBarrier can be used instead
	 */
	CLEvent enqueueCopyBuffer(CLBuffer srcBuffer, CLBuffer dstBuffer, size_t srcOffset, size_t dstOffset, size_t size, CLEvents waitlist = null)
	{
		cl_event event;
		cl_int res = clEnqueueCopyBuffer(_object, srcBuffer.getObject(), dstBuffer.getObject(), srcOffset, dstOffset, size, waitlist.length, waitlist.ptr, &event);
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",		""],
			["CL_INVALID_CONTEXT",				"context associated with command queue, srcBuffer and dstBuffer are not the same or if the context associated with command queue and events in waitlist are not the same"],
			["CL_INVALID_MEM_OBJECT",			""],
			["CL_INVALID_VALUE",				"srcOffset, dstOffset, size, srcOffset + size or dstOffset + size require accessing elements outside the srcBuffer and dstBuffer buffer objects respectively"],
			["CL_INVALID_EVENT_WAIT_LIST",		"event objects in waitlist are not valid events"],
			["CL_MISALIGNED_SUB_BUFFER_OFFSET",	"srcBuffer or dstBuffer is a sub-buffer object and offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"],
			["CL_MEM_COPY_OVERLAP",				"srcBuffer and dstBuffer are the same buffer object and the source and destination regions overlap"],
			["CL_MEM_OBJECT_ALLOCATION_FAILURE","there is a failure to allocate memory for data store associated with srcBuffer or dstBuffer"],
			["CL_OUT_OF_RESOURCES",				""],
			["CL_OUT_OF_HOST_MEMORY",			""]
		));
		
		return new CLEvent(event);
	}
	
	/**
	 *	enqueues a command to copy a 2D or 3D rectangular region from the buffer object identified by
	 *	srcBuffer to a 2D or 3D region in the buffer object identified by dstBuffer
	 *
	 *	Params:
	 *	    srcOrigin	=	(x, y, z) offset in the memory region associated with srcBuffer.
	 *						For a 2D rectangle region, the z value given by src_origin[2] should be 0.
	 *						The offset in bytes is computed as src_origin[2] * srcSlicePitch + src_origin[1] * srcRowPitch + src_origin[0]
	 *		dstOrigin	=	analogous to above
	 *		region		=	(width, height, depth) in bytes of the 2D or 3D rectangle being copied.
	 *						For a 2D rectangle, the depth value given by region[2] should be 1
	 *		srcRowPitch	=	length of each row in bytes to be used for the memory region associated with srcBuffer.
	 *						If srcRowPitch is 0, srcRowPitch is computed as region[0]
	 *		srcSlicePitch=	length of each 2D slice in bytes to be used for the memory region associated with srcBuffer.
	 *						If srcSlicePitch is 0, srcSlicePitch is computed as region[1] * srcRowPitch
	 *
	 *	Returns:
	 *		an event object that identifies this particular copy command and can be used to
	 *		query or queue a wait for this particular command to complete
	 *		The event can be ignored in which case it will not be possible for the application to query the status of this command or queue a
	 *		wait for this command to complete.  clEnqueueBarrier can be used instead
	 */
	CLEvent enqueueCopyBufferRect(CLBuffer srcBuffer, CLBuffer dstBuffer, const size_t[3] srcOrigin, const size_t[3] dstOrigin, const size_t[3] region,
            CLEvents waitlist = null, size_t srcRowPitch = 0, size_t srcSlicePitch = 0, size_t dstRowPitch = 0, size_t dstSlicePitch = 0)
	in
	{
		assert(region[0] != 0u && region[1] != 0u && region[2] != 0u);
		if (srcRowPitch > 0)
			assert(srcRowPitch >= region[0]);
		if (dstRowPitch > 0)
			assert(dstRowPitch >= region[0]);
		if (srcSlicePitch > 0)
			assert(srcSlicePitch >= region[1] * srcRowPitch);
		if (dstSlicePitch > 0)
			assert(dstSlicePitch >= region[1] * dstRowPitch);
	}
	body
	{
		cl_event event;
		cl_int res = clEnqueueCopyBufferRect(_object, srcBuffer.getObject(), dstBuffer.getObject(), srcOrigin.ptr, dstOrigin.ptr, region.ptr, srcRowPitch, srcSlicePitch, dstRowPitch, dstSlicePitch, waitlist.length, waitlist.ptr, &event);
		
		mixin(exceptionHandling(
			["CL_INVALID_COMMAND_QUEUE",		""],
			["CL_INVALID_CONTEXT",				"context associated with command queue, srcBuffer and dstBuffer are not the same or if the context associated with command queue and events in waitlist are not the same"],
			["CL_INVALID_MEM_OBJECT",			""],
			["CL_INVALID_VALUE",				"(src_origin, region) or (dstOrigin, region) require accessing elements outside the srcBuffer and dstBuffer buffer objects respectively"],
			["CL_INVALID_EVENT_WAIT_LIST",		"event objects in waitlist are not valid events"],
			["CL_MISALIGNED_SUB_BUFFER_OFFSET",	"srcBuffer or dstBuffer is a sub-buffer object and offset specified when the sub-buffer object is created is not aligned to CL_DEVICE_MEM_BASE_ADDR_ALIGN value for device associated with queue"],
			["CL_MEM_COPY_OVERLAP",				"srcBuffer and dstBuffer are the same buffer object and the source and destination regions overlap"],
			["CL_MEM_OBJECT_ALLOCATION_FAILURE","there is a failure to allocate memory for data store associated with srcBuffer or dstBuffer"],
			["CL_OUT_OF_RESOURCES",				""],
			["CL_OUT_OF_HOST_MEMORY",			""]
		));
		
		return new CLEvent(event); // TODO: what happens if the return value is ignored in terms of release(event)?
	}
	
	//! are the commands queued in the command queue executed out-of-order
	@property bool outOfOrder()
	{
		return cast(bool) (getInfo!(cl_command_queue_properties)(CL_QUEUE_PROPERTIES) & CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE);
	}
	
	//! is profiling of commands in the command-queue enabled
	@property bool profiling()
	{
		return cast(bool) (getInfo!(cl_command_queue_properties)(CL_QUEUE_PROPERTIES) & CL_QUEUE_PROFILING_ENABLE);
	}
}