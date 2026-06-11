import glob

from setuptools import find_packages, setup

package_name = "material_vision"

_ = setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml"]),
        ("share/" + package_name + "/config", glob.glob("config/*")),
        ("share/" + package_name + "/launch", glob.glob("launch/*")),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Anton Tetov Johansson",
    maintainer_email="anton@tetov.se",
    description="Build a model of what you're building",
    license="Apache-2.0",
    extras_require={
        "test": [
            "pytest",
        ],
    },
    entry_points={},
)
