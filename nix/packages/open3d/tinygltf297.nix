{
  packageSources,
  tinygltf,
}:
tinygltf.overrideAttrs (_old: {
  version = "2.9.7";

  src = packageSources.tinygltf297;
})
