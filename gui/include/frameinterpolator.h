#pragma once

#include <functional>

#ifdef __cplusplus
extern "C" {
#endif
#include <libavutil/frame.h>
#ifdef __cplusplus
}
#endif

/**
 * Makes the frame halfway between consecutive decoded frames.
 *
 * Submit() remembers `src` as the newest frame and, when possible, starts an
 * asynchronous interpolation between the previous frame and `src`. It returns
 * true when `done` will be called exactly once, with a software NV12 AVFrame
 * (or nullptr on failure). It returns false, without calling `done`, for the
 * first frame, after `discontinuity`, after a size or format change, or for
 * unsupported input.
 *
 * Submit() and Reset() must be called from one thread. `done` runs on another
 * thread.
 */
class FrameInterpolator
{
public:
	using Callback = std::function<void(AVFrame *mid)>;
	virtual ~FrameInterpolator() = default;
	virtual bool Submit(const AVFrame *src, bool discontinuity, Callback done) = 0;
	/** Forgets the previous frame, for example when a stream ends. */
	virtual void Reset() = 0;
};
