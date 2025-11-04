from setuptools import find_packages, setup

package_name = "pointless"

setup(
    name=package_name,
    version="0.1.0",
    packages=find_packages(exclude=["test"]),
    data_files=[
        ("share/ament_index/resource_index/packages", ["resource/" + package_name]),
        ("share/" + package_name, ["package.xml"]),
    ],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Anton Tetov",
    maintainer_email="anton@tetov.se",
    description="Filter some point clouds to get less points",
    license="Apache-2.0",
    entry_points={
        "console_scripts": ["pointless_filtering = pointless.pointless_filtering:main"],
    },
)
