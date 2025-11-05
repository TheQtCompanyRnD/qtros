pragma Singleton

import QtQuick
import QtQuick3D
import QtROS2.GeometryMsgs

QtObject {
    function toVector3d(v: qtros2geometrymsgs_vector3): vector3d {
        return Qt.vector3d(v.x, v.y, v.z)
    }

    // Orientation: project onto XY (ignore roll/pitch, keep yaw)
    function toQuaternion(r: qtros2geometrymsgs_quaternion): quaternion {
        return Qt.quaternion(r.w, r.x, r.y, r.z)
    }
}
