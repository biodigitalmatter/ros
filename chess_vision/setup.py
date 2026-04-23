import glob
from setuptools import find_packages, setup

package_name = "chess_vision"

setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name + "/launch", glob.glob("launch/*")),
        ("share/" + package_name, ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="tetov",
    maintainer_email="anton@tetov.se",
    description="detect charco boards",
    license="Apache-2.0",
    extras_require={
        "test": [
            "pytest",
        ],
    },
    entry_points={
        "console_scripts": [
            "charuco_tracker_node = chess_vision.charuco_tracker_node:main",
            "test_camera_info_publisher = chess_vision.tests.nodes.camera_info_publisher:main",
        ],
    },
)
