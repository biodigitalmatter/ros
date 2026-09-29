{
  packageSources,

  cmake,
  cudaPackages,
  ninja,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "stdgpu";
  version = "1.3.0-unstable-2024-11-28";

  src = packageSources.stdgpu;

  nativeBuildInputs = [
    cmake
    cudaPackages.cuda_nvcc
    ninja
  ];

  buildInputs = [
    cudaPackages.cccl
    cudaPackages.cuda_cudart
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DSTDGPU_BUILD_SHARED_LIBS=OFF"
    "-DSTDGPU_BUILD_TESTS=OFF"
    "-DSTDGPU_BUILD_EXAMPLES=OFF"
    "-DSTDGPU_BUILD_BENCHMARKS=OFF"
    "-DSTDGPU_BUILD_DOCUMENTATION=OFF"
    "-DSTDGPU_SETUP_COMPILER_FLAGS=OFF"
    "-DSTDGPU_BACKEND=STDGPU_BACKEND_CUDA"
    "-DCMAKE_CUDA_ARCHITECTURES=75;80;86;89;90"
    "-DTHRUST_INCLUDE_DIR=${cudaPackages.cccl}/include"
  ];

  doCheck = false;
}
