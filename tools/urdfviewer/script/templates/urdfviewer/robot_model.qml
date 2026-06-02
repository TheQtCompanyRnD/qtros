
{% macro v3(x, y, z) -%}
Qt.vector3d({{ x }}, {{ y }}, {{ z }})
{%- endmacro %}

{% macro quat(r) -%}
{{ r | qt_quat }}
{%- endmacro %}

{# Emit a single collision shape block at the given indent level. #}
{% macro shape_block(s, d) %}
{{ indent * d }}{% if s.shape_type == 'BoxShape' %}BoxShape {
{{ indent * (d+1) }}extents: {{ v3(s.extents[0]|round(6), s.extents[1]|round(6), s.extents[2]|round(6)) }}
{% if s.origin_xyz != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}position: {{ v3(s.origin_xyz[0]|round(6), s.origin_xyz[1]|round(6), s.origin_xyz[2]|round(6)) }}
{% endif %}
{% if s.origin_rpy != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}rotation: {{ quat(s.origin_rpy) }}
{% endif %}
{{ indent * d }}}
{% elif s.shape_type == 'SphereShape' %}SphereShape {
{{ indent * (d+1) }}diameter: {{ s.diameter|round(6) }}
{% if s.origin_xyz != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}position: {{ v3(s.origin_xyz[0]|round(6), s.origin_xyz[1]|round(6), s.origin_xyz[2]|round(6)) }}
{% endif %}
{% if s.origin_rpy != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}rotation: {{ quat(s.origin_rpy) }}
{% endif %}
{{ indent * d }}}
{% else %}CapsuleShape {
{{ indent * (d+1) }}diameter: {{ s.diameter|round(6) }}
{{ indent * (d+1) }}height: {{ s.height|round(6) }}
{% if s.origin_xyz != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}position: {{ v3(s.origin_xyz[0]|round(6), s.origin_xyz[1]|round(6), s.origin_xyz[2]|round(6)) }}
{% endif %}
{% if s.origin_rpy != [0.0, 0.0, 0.0] %}
{{ indent * (d+1) }}rotation: {{ quat(s.origin_rpy) }}
{% endif %}
{{ indent * d }}}
{% endif %}
{%- endmacro %}

{# Render one tree node.  is_root is True for the top-level link (no parent joint). #}
{% macro render(node, depth, is_root) -%}
{% set shapes = (node.link | collision_shapes(scene_units_per_meter)) if physics else [] %}
{% set movable = node.joint and node.joint.type in ['revolute', 'prismatic', 'continuous'] %}
{% if movable %}
{% set d = depth + 2 %}
{% else %}
{% set d = depth + (1 if node.joint else 0) %}
{% endif %}
{# When physics is on, every link (including root) gets a kinematic DynamicRigidBody. #}
{% set use_body = physics %}
{# body_d: indent level of the DynamicRigidBody.
   For root there is no joint Node, so we add 1 relative to depth.
   For non-root d already accounts for the joint-offset Node. #}
{% set body_d = (depth + 1) if (is_root and use_body) else d %}
{# content_d: indent level of visual/child content (one inside body_d when use_body). #}
{% set content_d = body_d + (1 if use_body else 0) %}
{# === Outer container: plain Node === #}
{{ indent * depth }}Node {
{% if is_root and use_body %}
{{ indent * body_d }}DynamicRigidBody {
{{ indent * (body_d+1) }}id: {{ node.link.name | qml_id }}Physics
{{ indent * (body_d+1) }}isKinematic: true
{% if shapes %}
{{ indent * (body_d+1) }}collisionShapes: [
{% for s in shapes %}
{{ shape_block(s, body_d + 2) }}{% if not loop.last %},{% endif %}
{% endfor %}
{{ indent * (body_d+1) }}]
{% endif %}
{% endif %}
{% if node.joint %}
{{ indent * (depth + 1) }}id: {{ node.joint.name | qml_id }}
{{ indent * (depth + 1) }}position: {{ v3((node.joint.xyz[0] * scene_units_per_meter)|round(6), (node.joint.xyz[1] * scene_units_per_meter)|round(6), (node.joint.xyz[2] * scene_units_per_meter)|round(6)) }}
{% if node.joint.rpy != [0.0, 0.0, 0.0] %}
{{ indent * (depth + 1) }}rotation: {{ quat(node.joint.rpy) }}
{% endif %}
{% endif %}
{# === Pivot for movable joints === #}
{% if movable %}
{{ indent * (depth + 1) }}Node {
{{ indent * (depth + 2) }}id: {{ node.joint.name | qml_id }}Pivot
{{ indent * (depth + 2) }}readonly property vector3d axis: {{ v3(node.joint.axis[0], node.joint.axis[1], node.joint.axis[2]) }}
{% if node.joint.type == 'prismatic' %}
{{ indent * (depth + 2) }}position: {{ v3('axis.x * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter', 'axis.y * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter', 'axis.z * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter') }}
{% else %}
{{ indent * (depth + 2) }}rotation: Quaternion.fromAxisAndAngle(axis, rootNode.toEulerAngle(rootNode.control.{{ node.joint | joint_prop_name }}))
{% endif %}
{% endif %}
{# === DynamicRigidBody wrapper for non-root links (root's is above) === #}
{% if use_body and not is_root %}
{{ indent * body_d }}DynamicRigidBody {
{{ indent * (body_d+1) }}id: {{ node.link.name | qml_id }}Physics
{{ indent * (body_d+1) }}isKinematic: true
{% if node.link.inertial %}
{{ indent * (body_d+1) }}mass: {{ node.link.inertial.mass }}
{% if node.link.inertial.ixx or node.link.inertial.iyy or node.link.inertial.izz %}
{{ indent * (body_d+1) }}massMode: DynamicRigidBody.MassAndInertiaMatrix
{{ indent * (body_d+1) }}// inertia matrix: [ixx, ixy, ixz, iyx, iyy, iyz, izx, izy, izz]
{{ indent * (body_d+1) }}inertiaMatrix: [{{ node.link.inertial.ixx }}, {{ node.link.inertial.ixy }}, {{ node.link.inertial.ixz }}, {{ node.link.inertial.ixy }}, {{ node.link.inertial.iyy }}, {{ node.link.inertial.iyz }}, {{ node.link.inertial.ixz }}, {{ node.link.inertial.iyz }}, {{ node.link.inertial.izz }}]
{% endif %}
{% endif %}
{% if shapes %}
{{ indent * (body_d+1) }}collisionShapes: [
{% for s in shapes %}
{{ shape_block(s, body_d + 2) }}{% if not loop.last %},{% endif %}
{% endfor %}
{{ indent * (body_d+1) }}]
{% endif %}
{% endif %}
{# === Visual mesh components (inside physics body when use_body, at content_d) === #}
{% if node.link.visuals %}
{% for v in node.link.visuals %}
{{ indent * content_d }}{% if v.geom.type == 'mesh' %}{{ v.geom.mesh_file | mesh_component(node.link.name) }}{% elif v.geom.type == 'node' %}Node{% else %}Model{% endif %} {
{{ indent * content_d }}    id: {{ node.link.name | qml_id }}{% if not loop.first %}{{ loop.index0 }}{% endif %}

{% if v.xyz != [0.0, 0.0, 0.0] %}
{{ indent * content_d }}    position: {{ v3((v.xyz[0] * scene_units_per_meter)|round(6), (v.xyz[1] * scene_units_per_meter)|round(6), (v.xyz[2] * scene_units_per_meter)|round(6)) }}
{% endif %}
{% set mesh_offset = v.geom.type == 'mesh' and mesh_rotation != zero_rpy %}
{% if v.rpy != zero_rpy or mesh_offset %}
{{ indent * content_d }}    rotation: {{ v.rpy | qt_quat_with_offset(mesh_rotation if v.geom.type == 'mesh' else zero_rpy) }}
{% endif %}
{% if v.geom.type == 'mesh' %}
{{ indent * content_d }}    scale: {{ v3((scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[0])|round(6), (scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[1])|round(6), (scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[2])|round(6)) }}
{% elif v.geom.type == 'box' %}
{{ indent * content_d }}    source: "#Cube"
{{ indent * content_d }}    scale: {{ v3((v.geom.size[0] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[1] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[2] * scene_units_per_meter / 100.0)|round(6)) }}
{% elif v.geom.type == 'cylinder' %}
{{ indent * content_d }}    source: "#Cylinder"
{{ indent * content_d }}    scale: {{ v3((v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[1] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6)) }}
{% elif v.geom.type == 'sphere' %}
{{ indent * content_d }}    source: "#Sphere"
{{ indent * content_d }}    scale: {{ v3((v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6)) }}
{% endif %}
{% if v.geom.type not in ['mesh', 'node'] and v.material and v.material.color and not v.material.texture %}
{{ indent * content_d }}    materials: [ PrincipledMaterial { baseColor: {{ v.material.color | qt_rgba }} } ]
{% elif not (v.material and v.material.texture) and v.geom.type not in ['mesh', 'node'] %}
{{ indent * content_d }}    materials: [ PrincipledMaterial { } ]
{% endif %}
{{ indent * content_d }}}
{% endfor %}
{% else %}
{{ indent * content_d }}Node {
{{ indent * content_d }}    id: {{ node.link.name | qml_id }}
{{ indent * content_d }}}
{% endif %}
{# === Child nodes (inside physics body when use_body) === #}
{% for c in node.children %}
{{ render(c, content_d, false) }}
{% endfor %}
{# === Closings (innermost first) === #}
{% if use_body %}
{{ indent * body_d }}}
{% endif %}
{% if movable %}
{{ indent * (depth + 1) }}}
{% endif %}
{{ indent * depth }}}
{%- endmacro %}

import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
{% if physics %}
import QtQuick3D.Physics
{% endif %}
{% for c in components %}
import {{ c }}
{% endfor %}

Node {
    id: rootNode

{{ indent }}{{ control_decl }}
{{ indent }}property real sceneUnitsPerMeter: {{ scene_units_per_meter|round(6) }}
{{ indent }}property real instanceScale: {{ instance_scale|round(6) }}
{{ indent }}scale: {{ v3('instanceScale', 'instanceScale', 'instanceScale') }}

{{ indent }}function toEulerAngle(radians) { return radians * (180 / Math.PI) }


{% for a in aliases %}
{{ indent }}{{ a }}
{% endfor %}

{% if axis_transform %}
{{ indent }}// Convert to Y-up
{{ indent }}rotation: {{ quat([-pi/2, -pi/2, 0]) }}
{% endif %}

{{ render(root, 1, true) }}
}
