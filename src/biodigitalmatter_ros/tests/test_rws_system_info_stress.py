"""Stress-test repeated startup of the existing RWS launch file.

Exposes HTTP 503 Too many sessions 70/70 failures."""

import launch
import launch_pytest
import pytest
import rclpy
from abb_robot_msgs.msg import ServiceResponses
from abb_robot_msgs.srv import GetRobotControllerDescription
from ament_index_python.packages import get_package_share_path
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import AnyLaunchDescriptionSource
from rclpy.context import Context
from rclpy.executors import SingleThreadedExecutor
from rclpy.qos import qos_profile_sensor_data
from rclpy.wait_for_message import wait_for_message
from sensor_msgs.msg import JointState

ITERATIONS = 20
STARTUP_TIMEOUT = 20.0
POLLING_TIMEOUT = 5.0


@launch_pytest.fixture(
    params=range(1, ITERATIONS + 1),
    ids=lambda iteration: f"iteration-{iteration:02d}",
)
def rws_launch(request):
    launch_file = (
        get_package_share_path("biodigitalmatter_ros") / "launch" / "rws.launch.yaml"
    )
    return (
        launch.LaunchDescription(
            [
                IncludeLaunchDescription(AnyLaunchDescriptionSource(launch_file)),
                launch_pytest.actions.ReadyToTest(),
            ]
        ),
        request.param,
    )


@pytest.mark.hardware
@pytest.mark.launch(fixture=rws_launch)
def test_rws_initializes(rws_launch):
    _, iteration = rws_launch
    context = Context()
    executor = None
    node = None

    try:
        rclpy.init(context=context)
        node = rclpy.create_node(
            f"test_rws_initialization_{iteration}", context=context
        )
        executor = SingleThreadedExecutor(context=context)
        executor.add_node(node)
        client = node.create_client(
            GetRobotControllerDescription,
            "/rws_client/get_robot_controller_description",
        )

        assert client.wait_for_service(timeout_sec=STARTUP_TIMEOUT), (
            "RWS controller-description service did not become available"
        )

        future = client.call_async(GetRobotControllerDescription.Request())
        executor.spin_until_future_complete(future, timeout_sec=POLLING_TIMEOUT)
        response = future.result()

        assert response is not None, "RWS controller-description service timed out"
        assert response.result_code == ServiceResponses.RC_SUCCESS
        assert "robot_ware_version" in response.description
        assert "system_name" in response.description

        received, joint_state = wait_for_message(
            JointState,
            node,
            "/joint_states",
            qos_profile=qos_profile_sensor_data,
            time_to_wait=POLLING_TIMEOUT,
        )
        assert received, "RWS state publisher did not publish joint states"
        assert joint_state.name, "RWS joint state has no joints"
    finally:
        if executor is not None:
            executor.shutdown()
        if node is not None:
            node.destroy_node()
        if context.ok():
            rclpy.shutdown(context=context)
