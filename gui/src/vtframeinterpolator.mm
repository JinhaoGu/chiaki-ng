#include "vtframeinterpolator.h"

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

extern "C" {
#include <libavutil/pixfmt.h>
}

// VTLowLatencyFrameInterpolation needs macOS 26. The app targets macOS 12, so
// every use sits behind @available and VideoToolbox symbols are weak-linked.

namespace {

void release_pixel_buffer(void *opaque, uint8_t *)
{
	CVPixelBufferRef pb = static_cast<CVPixelBufferRef>(opaque);
	CVPixelBufferUnlockBaseAddress(pb, kCVPixelBufferLock_ReadOnly);
	CVPixelBufferRelease(pb);
}

// Wraps an NV12 pixel buffer as a software AVFrame without copying.
// Takes over one reference of `pb`.
AVFrame *wrap_nv12(CVPixelBufferRef pb, const AVFrame *props)
{
	if (CVPixelBufferLockBaseAddress(pb, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess) {
		CVPixelBufferRelease(pb);
		return nullptr;
	}
	AVFrame *out = av_frame_alloc();
	AVBufferRef *buf = out ? av_buffer_create(static_cast<uint8_t *>(CVPixelBufferGetBaseAddressOfPlane(pb, 0)),
		CVPixelBufferGetDataSize(pb), release_pixel_buffer, pb, AV_BUFFER_FLAG_READONLY) : nullptr;
	if (!buf) {
		av_frame_free(&out);
		release_pixel_buffer(pb, nullptr);
		return nullptr;
	}
	av_frame_copy_props(out, props);
	out->format = AV_PIX_FMT_NV12;
	out->width = props->width;
	out->height = props->height;
	out->buf[0] = buf;
	for (int plane = 0; plane < 2; plane++) {
		out->data[plane] = static_cast<uint8_t *>(CVPixelBufferGetBaseAddressOfPlane(pb, plane));
		out->linesize[plane] = int(CVPixelBufferGetBytesPerRowOfPlane(pb, plane));
	}
	out->crop_top = out->crop_bottom = out->crop_left = out->crop_right = 0;
	return out;
}

} // namespace

struct VTFrameInterpolator::Impl
{
	id processor = nil; // VTFrameProcessor
	CVPixelBufferPoolRef pool = nullptr;
	CVPixelBufferRef previous = nullptr;
	AVFrame *previous_props = nullptr;
	int width = 0, height = 0;
	OSType format = 0;
	int64_t sequence = 0;
	bool failed = false;

	void EndSession()
	{
		if (processor) {
			if (@available(macOS 26.0, *))
				[(VTFrameProcessor *)processor endSession];
		}
		processor = nil;
		if (pool) {
			CVPixelBufferPoolRelease(pool);
			pool = nullptr;
		}
		width = height = 0;
	}

	void ForgetPrevious()
	{
		if (previous) {
			CVPixelBufferRelease(previous);
			previous = nullptr;
		}
		av_frame_free(&previous_props);
	}

	bool StartSession(int w, int h)
	{
		EndSession();
		if (@available(macOS 26.0, *)) {
			VTLowLatencyFrameInterpolationConfiguration *config =
				[[VTLowLatencyFrameInterpolationConfiguration alloc] initWithFrameWidth:w frameHeight:h numberOfInterpolatedFrames:1];
			if (!config)
				return false;
			VTFrameProcessor *p = [VTFrameProcessor new];
			NSError *err = nil;
			if (![p startSessionWithConfiguration:config error:&err]) {
				NSLog(@"VTFrameInterpolator: start session failed: %@", err);
				return false;
			}
			if (CVPixelBufferPoolCreate(kCFAllocatorDefault, nullptr,
					(__bridge CFDictionaryRef)config.destinationPixelBufferAttributes, &pool) != kCVReturnSuccess) {
				[p endSession];
				return false;
			}
			processor = p;
			width = w;
			height = h;
			return true;
		}
		return false;
	}

	~Impl()
	{
		ForgetPrevious();
		EndSession();
	}
};

VTFrameInterpolator::VTFrameInterpolator() : impl(new Impl) {}

VTFrameInterpolator::~VTFrameInterpolator()
{
	delete impl;
}

bool VTFrameInterpolator::IsSupported()
{
	if (@available(macOS 26.0, *))
		return VTLowLatencyFrameInterpolationConfiguration.isSupported;
	return false;
}

void VTFrameInterpolator::Reset()
{
	impl->ForgetPrevious();
}

bool VTFrameInterpolator::Submit(const AVFrame *src, bool discontinuity, Callback done)
{
	if (impl->failed || !src || src->format != AV_PIX_FMT_VIDEOTOOLBOX || !src->data[3])
		return false;

	CVPixelBufferRef current = reinterpret_cast<CVPixelBufferRef>(src->data[3]);
	const OSType format = CVPixelBufferGetPixelFormatType(current);
	const int w = int(CVPixelBufferGetWidth(current));
	const int h = int(CVPixelBufferGetHeight(current));
	if (format != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
		impl->ForgetPrevious();
		return false;
	}

	const bool restart = discontinuity || w != impl->width || h != impl->height || format != impl->format;
	if (w != impl->width || h != impl->height) {
		if (!impl->StartSession(w, h)) {
			NSLog(@"VTFrameInterpolator: cannot interpolate %dx%d, disabling", w, h);
			impl->failed = true;
			impl->ForgetPrevious();
			return false;
		}
	}
	impl->format = format;

	// Keep the new frame as the next "previous" frame either way.
	CVPixelBufferRef previous = impl->previous;
	AVFrame *previous_props = impl->previous_props;
	impl->previous = CVPixelBufferRetain(current);
	impl->previous_props = av_frame_alloc();
	if (impl->previous_props)
		av_frame_copy_props(impl->previous_props, src);
	const int64_t seq = ++impl->sequence;

	if (restart || !previous) {
		if (previous)
			CVPixelBufferRelease(previous);
		av_frame_free(&previous_props);
		return false;
	}
	av_frame_free(&previous_props);

	if (@available(macOS 26.0, *)) {
		CVPixelBufferRef out_pb = nullptr;
		if (CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, impl->pool, &out_pb) != kCVReturnSuccess) {
			CVPixelBufferRelease(previous);
			return false;
		}
		// The VTFrameProcessorFrame objects retain the pixel buffers until processing ends.
		VTFrameProcessorFrame *prev_frame = [[VTFrameProcessorFrame alloc] initWithBuffer:previous presentationTimeStamp:CMTimeMake(seq - 1, 120)];
		VTFrameProcessorFrame *cur_frame = [[VTFrameProcessorFrame alloc] initWithBuffer:current presentationTimeStamp:CMTimeMake(seq, 120)];
		VTFrameProcessorFrame *dst_frame = [[VTFrameProcessorFrame alloc] initWithBuffer:out_pb presentationTimeStamp:CMTimeMake(seq * 2 - 1, 240)];
		CVPixelBufferRelease(previous);
		if (!prev_frame || !cur_frame || !dst_frame) {
			CVPixelBufferRelease(out_pb);
			return false;
		}
		VTLowLatencyFrameInterpolationParameters *params =
			[[VTLowLatencyFrameInterpolationParameters alloc] initWithSourceFrame:cur_frame previousFrame:prev_frame
															 interpolationPhase:@[@0.5f] destinationFrames:@[dst_frame]];
		if (!params) {
			CVPixelBufferRelease(out_pb);
			return false;
		}
		AVFrame *props = av_frame_alloc();
		if (props) {
			av_frame_copy_props(props, src);
			props->width = src->width;
			props->height = src->height;
		}
		auto callback = std::make_shared<Callback>(std::move(done));
		[(VTFrameProcessor *)impl->processor processWithParameters:params
			completionHandler:^(id<VTFrameProcessorParameters>, NSError *err) {
				AVFrame *mid = nullptr;
				if (err)
					NSLog(@"VTFrameInterpolator: interpolation failed: %@", err);
				else if (props)
					mid = wrap_nv12(CVPixelBufferRetain(out_pb), props);
				CVPixelBufferRelease(out_pb);
				AVFrame *p = props;
				av_frame_free(&p);
				(*callback)(mid);
			}];
		return true;
	}
	CVPixelBufferRelease(previous);
	return false;
}
