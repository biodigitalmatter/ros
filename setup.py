from glob import glob
import os
from pathlib import Path

from setuptools import setup

package_name = 'biodigitalmatter_ros'

share_dir = Path('share') / package_name

setup(
 name=package_name,
 version='0.0.0',
 packages=[package_name],
 data_files=[
     ('share/ament_index/resource_index/packages',
             ['resource/' + package_name]),
     (str(share_dir), ['package.xml']),
     (str(share_dir / "launch"), glob("*launch.[pxy][yma]*", root_dir="launch")),
     (str(share_dir / "config"), glob("*.y?ml", root_dir="config"))
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
