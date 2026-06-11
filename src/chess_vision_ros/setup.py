import glob

from setuptools import find_packages, setup

package_name = "chess_vision_ros"

_ = setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml"]),
        ("share/" + package_name + "/launch", glob.glob("launch/*")),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Anton Tetov Johansson",
    maintainer_email="anton@tetov.se",
    description="ROS wrapper for chess_vision",
    license="Apache-2.0",
    extras_require={
        "test": [
            "pytest",
        ],
    },
    entry_points={
        "console_scripts": [
            "charuco_tracker_node = chess_vision_ros.charuco_tracker_node:main",
            "aruco_tracker_node = chess_vision_ros.aruco_tracker_node:main",
            "dummy_camera_info_publisher = chess_vision_ros.dummy_camera_info_publisher:main",
        ],
    },
)
