from launch import LaunchDescription
from launch_ros.actions import ComposableNodeContainer, Node
from launch_ros.descriptions import ComposableNode


def generate_launch_description():
    return LaunchDescription(
        [
            # Point cloud filtering
            ComposableNodeContainer(
                name="pcl_container",
                namespace="",
                package="rclcpp_components",
                executable="component_container",
                composable_node_descriptions=[
                    ComposableNode(
                        package="pcl_ros",
                        plugin="pcl_ros::VoxelGrid",
                        name="voxel_grid",
                        remappings=[
                            ("input", "/rgbd_camera/points"),
                            ("output", "/rgbd_camera/points_filtered"),
                        ],
                        parameters=[{"leaf_size": 0.01}],
                    ),
                ],
            ),
            # OctoMap generation
            Node(
                package="octomap_server",
                executable="octomap_server_node",
                name="octomap_server",
                parameters=[
                    {
                        "resolution": 0.01,
                        "frame_id": "map",
                        "sensor_model/max_range": 5.0,
                        "queue_size": 100,
                    }
                ],
                remappings=[("cloud_in", "/rgbd_camera/points_filtered")],
            ),
        ]
    )
