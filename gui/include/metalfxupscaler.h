#pragma once

#ifdef __cplusplus
extern "C" {
#endif
#include <libavutil/frame.h>
#ifdef __cplusplus
}
#endif

/**
 * Upscales VideoToolbox-decoded frames with the MetalFX spatial scaler (macOS 13+).
 *
 * Input: an AVFrame with format AV_PIX_FMT_VIDEOTOOLBOX (NV12 or 10-bit biplanar 4:2:0).
 * Output: a new software AVFrame (AV_PIX_FMT_BGRA for SDR, AV_PIX_FMT_RGBA64LE for 10-bit),
 * backed by an IOSurface, sized to fit the target while keeping the aspect ratio.
 *
 * The output keeps the source transfer function (gamma or PQ) and primaries.
 * Only the YCbCr matrix is applied, so colorspace becomes AVCOL_SPC_RGB.
 *
 * Not thread-safe. Use one instance from one thread.
 */
class MetalFXUpscaler
{
public:
	MetalFXUpscaler();
	~MetalFXUpscaler();
	MetalFXUpscaler(const MetalFXUpscaler &) = delete;
	MetalFXUpscaler &operator=(const MetalFXUpscaler &) = delete;

	/** True when this Mac has a Metal device that supports the MetalFX spatial scaler. */
	static bool IsSupported();

	/**
	 * Returns a new upscaled frame, or nullptr when the frame is not handled
	 * (wrong format, no upscale needed, or a Metal error). The caller keeps
	 * ownership of src and owns the returned frame.
	 */
	AVFrame *Process(const AVFrame *src, int target_width, int target_height);

	/** Largest upscale factor per axis. Larger targets are clamped to this factor. */
	static constexpr double kMaxScale = 3.0;

private:
	struct Impl;
	Impl *impl;
};
