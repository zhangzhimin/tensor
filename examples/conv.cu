﻿#include <matazure/tensor>
#include <matazure/cuda/puzzle/conv.hpp>

using namespace matazure;

static_tensor<float, 3, 3> host_mask;
__constant__ struct static_tensor<float, 3, 3> mask;
MATAZURE_PUZZEL_CONV_GLOBAL(conv_global, mask)
MATAZURE_PUZZEL_CONV_BLOCK(conv_block, mask)

__constant__ float test[100];

int main() {
	fill(host_mask, 1.0f / host_mask.size());
	cuda::copy_symbol(host_mask, mask);

	auto saturate_fun  =   [] __matazure__ (float v)->byte {
		if (v < 0)	return byte(0);
		if (v > 255) return byte(255);
		return static_cast<byte>(v);
	};

	tensor<byte, 2> gray({ 512,512 });
	io::read_raw_data("data/lena_gray8_512x512.raw_data", gray);
	auto cu_gray = mem_clone(gray, device_t{});

	auto lcts_conv = cuda::puzzle::conv_global(tensor_cast<float>(cu_gray));
	auto cts_conv = apply(lcts_conv, saturate_fun).persist();
	auto ts_conv = mem_clone(cts_conv, host_t{});
	cuda::barrier();
	io::write_raw_data("data/lena_gray8_conv_512x512.raw_data", ts_conv);

	auto cts_block_conv = cuda::puzzle::conv_block<32, 32>(tensor_cast<float>(cu_gray));
	auto cts_byte_block_conv = apply(cts_block_conv, saturate_fun).persist();
	auto ts_byte_conv_block = mem_clone(cts_byte_block_conv, host_t{});
	cuda::barrier();
	io::write_raw_data("data/lena_gray8_conv_block_512x512.raw_data", ts_byte_conv_block);
}