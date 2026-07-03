from setuptools import find_packages, setup

package_name = "elizabeth_perception_filters"

_ = setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Anton Tetov Johansson",
    maintainer_email="anton@tetov.se",
    description="perception filters",
    license="Apache-2.0",
    extras_require={
        "test": [
            "pytest",
        ],
    },
    entry_points={
        "console_scripts": [
            "depth_image_filter_node = elizabeth_perception_filters.depth_image_filter_node:main",
        ],
    },
)
