# from glob import glob
import os
from pathlib import Path

from setuptools import setup

package_name = "biodigitalmatter_ros"

share_dir = Path("share") / package_name

setup(
 name=package_name,
 version="0.1.0",
 packages=[package_name],
 data_files=[
     ('share/ament_index/resource_index/packages',
             ['resource/' + package_name]),
     (str(share_dir), ['package.xml']),
     (str(share_dir / "launch"), [str(p) for p in Path("launch").glob("*launch.[pxy][yma]*")]),
     (str(share_dir / "config"), [str(p) for p in Path("config").glob("*.y?ml")])
   ],
 install_requires=['setuptools'],
 zip_safe=True,
 maintainer="Anton Tetov Johansson",
 maintainer_email = "anton@tetov.se",
 description="ROS setup for biodigital matter lab",
 license='MIT',
 tests_require=[],
 entry_points={},
)
