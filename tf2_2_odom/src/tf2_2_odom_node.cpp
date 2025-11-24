#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <tf2_ros/transform_listener.h>
#include <tf2_ros/buffer.h>
#include <geometry_msgs/msg/transform_stamped.hpp>
#include <tf2/LinearMath/Quaternion.h>

class Tf22OdomNode : public rclcpp::Node
{
public:
  Tf22OdomNode() : Node("tf2_2_odometry")
  {
    // Declare parameters
    this->declare_parameter<std::string>("relative_frame", "map");
    this->declare_parameter<std::string>("tracking_frame", "camera_link");
    this->declare_parameter<std::string>("odom_frame", "odom");
    this->declare_parameter<double>("publish_rate", 30.0);
    this->declare_parameter<double>("cov_translation", 0.0001);
    this->declare_parameter<double>("cov_rotation", 0.0001);

    // Get parameters
    relative_frame_ = this->get_parameter("relative_frame").as_string();
    tracking_frame_ = this->get_parameter("tracking_frame").as_string();
    odom_frame_ = this->get_parameter("odom_frame").as_string();
    double publish_rate = this->get_parameter("publish_rate").as_double();
    cov_translation_ = this->get_parameter("cov_translation").as_double();
    cov_rotation_ = this->get_parameter("cov_rotation").as_double();

    // Setup TF listener
    tf_buffer_ = std::make_shared<tf2_ros::Buffer>(this->get_clock());
    tf_listener_ = std::make_shared<tf2_ros::TransformListener>(*tf_buffer_);

    // Create publisher
    odom_publisher_ = this->create_publisher<nav_msgs::msg::Odometry>("/arm_odometry", 10);

    // Create timer for publishing at specified rate
    auto period = std::chrono::milliseconds(static_cast<int>(1000.0 / publish_rate));
    timer_ = this->create_wall_timer(period, std::bind(&Tf22OdomNode::publish_odometry, this));

    RCLCPP_INFO(this->get_logger(),
      "TF to Odometry converter started\n"
      "  Relative frame: %s\n"
      "  Tracking frame: %s\n"
      "  Odom frame: %s\n"
      "  Publish rate: %.1f Hz\n"
      "  Translation covariance: %.6f\n"
      "  Rotation covariance: %.6f",
      relative_frame_.c_str(), tracking_frame_.c_str(), odom_frame_.c_str(),
      publish_rate, cov_translation_, cov_rotation_);
  }

private:
  void publish_odometry()
  {
    try
    {
      // Lookup transform
      geometry_msgs::msg::TransformStamped transform =
        tf_buffer_->lookupTransform(relative_frame_, tracking_frame_, tf2::TimePointZero);

      // Create odometry message
      auto odom_msg = std::make_shared<nav_msgs::msg::Odometry>();
      odom_msg->header.stamp = transform.header.stamp;
      odom_msg->header.frame_id = odom_frame_;
      odom_msg->child_frame_id = tracking_frame_;

      // Position
      odom_msg->pose.pose.position.x = transform.transform.translation.x;
      odom_msg->pose.pose.position.y = transform.transform.translation.y;
      odom_msg->pose.pose.position.z = transform.transform.translation.z;

      // Orientation
      odom_msg->pose.pose.orientation = transform.transform.rotation;

      // pose covariance (6x6 matrix - only setting diagonal)
      odom_msg->pose.covariance[0] = cov_translation_;   // x variance
      odom_msg->pose.covariance[7] = cov_translation_;   // y variance
      odom_msg->pose.covariance[14] = cov_translation_;  // z variance
      odom_msg->pose.covariance[21] = cov_rotation_;     // roll variance
      odom_msg->pose.covariance[28] = cov_rotation_;     // pitch variance
      odom_msg->pose.covariance[35] = cov_rotation_;     // yaw variance

      // twist (zero for ~stationary~ arm)
      odom_msg->twist.twist.linear.x = 0.0;
      odom_msg->twist.twist.linear.y = 0.0;
      odom_msg->twist.twist.linear.z = 0.0;
      odom_msg->twist.twist.angular.x = 0.0;
      odom_msg->twist.twist.angular.y = 0.0;
      odom_msg->twist.twist.angular.z = 0.0;

      // twist covariance (also zero for stationary)
      for (size_t i = 0; i < 36; ++i)
      {
        odom_msg->twist.covariance[i] = 0.0;
      }

      odom_publisher_->publish(*odom_msg);
    }
    catch (const tf2::TransformException& ex)
    {
      RCLCPP_WARN_THROTTLE(this->get_logger(), *this->get_clock(), 5000,
        "TF lookup failed: %s", ex.what());
    }
  }

  std::string relative_frame_;
  std::string tracking_frame_;
  std::string odom_frame_;
  double cov_translation_;
  double cov_rotation_;

  std::shared_ptr<tf2_ros::Buffer> tf_buffer_;
  std::shared_ptr<tf2_ros::TransformListener> tf_listener_;
  rclcpp::Publisher<nav_msgs::msg::Odometry>::SharedPtr odom_publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Tf22OdomNode>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
