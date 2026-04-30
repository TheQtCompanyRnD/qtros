
{% macro v3(x, y, z) -%}
Qt.vector3d({{ x }}, {{ y }}, {{ z }})
{%- endmacro %}

{% macro quat(r) -%}
{{ r | qt_quat }}
{%- endmacro %}

{% macro render(node, depth) -%}
{{ indent * depth }}Node {
{% if node.joint %}
{{ indent * (depth + 1) }}id: {{ node.joint.name | qml_id }}
{{ indent * (depth + 1) }}position: {{ v3((node.joint.xyz[0] * scene_units_per_meter)|round(6), (node.joint.xyz[1] * scene_units_per_meter)|round(6), (node.joint.xyz[2] * scene_units_per_meter)|round(6)) }}
{% if node.joint.rpy != [0.0, 0.0, 0.0] %}
{{ indent * (depth + 1) }}rotation: {{ quat(node.joint.rpy) }}
{% endif %}
{% endif %}
{% set movable = node.joint and node.joint.type in ['revolute', 'prismatic', 'continuous'] %}
{% if movable %}
{{ indent * (depth + 1) }}Node {
{{ indent * (depth + 2) }}id: {{ node.joint.name | qml_id }}Pivot
{{ indent * (depth + 2) }}readonly property vector3d axis: {{ v3(node.joint.axis[0], node.joint.axis[1], node.joint.axis[2]) }}
{% if node.joint.type == 'prismatic' %}
{{ indent * (depth + 2) }}position: {{ v3('axis.x * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter', 'axis.y * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter', 'axis.z * rootNode.control.' ~ (node.joint | joint_prop_name) ~ ' * rootNode.sceneUnitsPerMeter') }}
{% else %}
{{ indent * (depth + 2) }}rotation: Quaternion.fromAxisAndAngle(axis, rootNode.toEulerAngle(rootNode.control.{{ node.joint | joint_prop_name }}))
{% endif %}
{% set d = depth + 2 %}
{% else %}
{% set d = depth + 1 %}
{% endif %}
{% if node.link.visuals %}
{% for v in node.link.visuals %}
{{ indent * d }}{% if v.geom.type == 'mesh' %}{{ v.geom.mesh_file | mesh_component(node.link.name) }}{% elif v.geom.type == 'node' %}Node{% else %}Model{% endif %} {
{{ indent * d }}    id: {{ node.link.name | qml_id }}{% if not loop.first %}{{ loop.index0 }}{% endif %}

{% if v.xyz != [0.0, 0.0, 0.0] %}
{{ indent * d }}    position: {{ v3((v.xyz[0] * scene_units_per_meter)|round(6), (v.xyz[1] * scene_units_per_meter)|round(6), (v.xyz[2] * scene_units_per_meter)|round(6)) }}
{% endif %}
{% set mesh_offset = v.geom.type == 'mesh' and mesh_rotation != zero_rpy %}
{% if v.rpy != zero_rpy or mesh_offset %}
{{ indent * d }}    rotation: {{ v.rpy | qt_quat_with_offset(mesh_rotation if v.geom.type == 'mesh' else zero_rpy) }}
{% endif %}
{% if v.geom.type == 'mesh' %}
{{ indent * d }}    scale: {{ v3((scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[0])|round(6), (scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[1])|round(6), (scene_units_per_meter * v.geom.mesh_unit_to_meter * v.geom.mesh_scale[2])|round(6)) }}
{% elif v.geom.type == 'box' %}
{{ indent * d }}    source: "#Cube"
{{ indent * d }}    scale: {{ v3((v.geom.size[0] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[1] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[2] * scene_units_per_meter / 100.0)|round(6)) }}
{% elif v.geom.type == 'cylinder' %}
{{ indent * d }}    source: "#Cylinder"
{{ indent * d }}    scale: {{ v3((v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[1] * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6)) }}
{% elif v.geom.type == 'sphere' %}
{{ indent * d }}    source: "#Sphere"
{{ indent * d }}    scale: {{ v3((v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6), (v.geom.size[0] * 2 * scene_units_per_meter / 100.0)|round(6)) }}
{% endif %}
{% if v.geom.type not in ['mesh', 'node'] and v.material and v.material.color and not v.material.texture %}
{{ indent * d }}    materials: [ PrincipledMaterial { baseColor: {{ v.material.color | qt_rgba }} } ]
{% elif not (v.material and v.material.texture) and v.geom.type not in ['mesh', 'node'] %}
{{ indent * d }}    materials: [ PrincipledMaterial { } ]
{% endif %}
{{ indent * d }}}
{% endfor %}
{% else %}
{{ indent * d }}Node {
{{ indent * d }}    id: {{ node.link.name | qml_id }}
{{ indent * d }}}
{% endif %}
{% for c in node.children %}
{{ render(c, depth + (2 if movable else 1)) }}
{% endfor %}
{% if movable %}
{{ indent * (depth + 1) }}}
{% endif %}
{{ indent * depth }}}
{%- endmacro %}

import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
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

{{ render(root, 1) }}
}
