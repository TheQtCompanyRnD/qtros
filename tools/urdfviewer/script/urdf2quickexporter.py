# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

"""URDF to Qt Quick 3D exporter.

This script converts a URDF robot description into a set of Qt Quick 3D
components along with optional C++ control sources.  Invoke it from the
command line as::

    python3 scripts/urdf2quick3dexporter.py <input.urdf> <dest_dir> [options]

The destination directory must already exist; the exporter creates a folder
under it containing the generated QML, C++, CMake files and joint metadata.
"""

import os
import math
import re
import shutil
import subprocess
import argparse
import sys
import tempfile
import xml.etree.ElementTree as ET
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, List, Optional, Dict, Tuple
import json

from urdf_parser_py.urdf import URDF, Mesh, Box, Cylinder, Sphere
from jinja2 import Environment, FileSystemLoader


def to_camel_case(name: str) -> str:
    """Convert snake_case or kebab-case strings to camelCase."""
    parts = re.split(r"[_-]+", name)
    if not parts:
        return name
    first = parts[0].lower()
    rest = "".join(p.capitalize() for p in parts[1:])
    return first + rest


def to_pascal_case(name: str) -> str:
    """Convert snake_case or kebab-case strings to PascalCase."""
    camel = to_camel_case(name)
    return camel[:1].upper() + camel[1:] if camel else ""


def qml_id(name: str) -> str:
    """Return a QML id-safe string derived from the given name."""
    # Allow only alphanumerics and underscore, and ensure a non-digit start.
    safe = re.sub(r"[^a-zA-Z0-9_]", "_", name)
    if not safe or safe[0].isdigit():
        safe = "_" + safe
    return safe.lower()


def joint_prop_name(j: "Joint") -> str:
    """Return the camelCase property name for a joint."""
    return to_camel_case(j.name) + ("Pos" if j.type == "prismatic" else "Angle")


def capitalize_first(name: str) -> str:
    """Return the string with the first character capitalized."""
    return name[:1].upper() + name[1:] if name else name


def mesh_component_name(mesh_file: str, fallback: str) -> str:
    """Return a QML-safe PascalCase type/module name derived from a mesh file."""
    basename = os.path.splitext(os.path.basename(mesh_file or ""))[0]
    source = basename if basename else fallback
    tokens = re.findall(r"[A-Za-z0-9]+", source)
    if not tokens:
        tokens = re.findall(r"[A-Za-z0-9]+", fallback) or ["Mesh"]
    name = "".join(token[:1].upper() + token[1:] for token in tokens)
    if not name:
        name = "Mesh"
    if not name[0].isalpha():
        name = "Mesh" + name
    return name


def _normalize_mesh_scale(scale: Optional[List[float]]) -> List[float]:
    """Return a 3-element mesh scale list, defaulting to 1.0."""
    if scale is None:
        return [1.0, 1.0, 1.0]
    if isinstance(scale, (int, float)):
        return [float(scale), float(scale), float(scale)]
    if not scale:
        return [1.0, 1.0, 1.0]
    if len(scale) == 1:
        value = float(scale[0])
        return [value, value, value]
    if len(scale) == 2:
        return [float(scale[0]), float(scale[1]), 1.0]
    return [float(scale[0]), float(scale[1]), float(scale[2])]


_MESH_UNIT_SCALE_TO_METER = {
    "meter": 1.0,
    "centimeter": 0.01,
    "millimeter": 0.001,
}


def _mesh_unit_factor(unit: str, custom_to_meter: float) -> float:
    if unit == "custom":
        return float(custom_to_meter)
    if unit in _MESH_UNIT_SCALE_TO_METER:
        return _MESH_UNIT_SCALE_TO_METER[unit]
    raise RuntimeError(f"Unsupported mesh unit '{unit}'")


def rpy_to_quat(roll: float, pitch: float, yaw: float):
    """
    URDF RPY (fixed X-Y-Z axes) to quaternion (w, x, y, z).
    All angles in radians.
    """
    cy = math.cos(yaw * 0.5)
    sy = math.sin(yaw * 0.5)
    cp = math.cos(pitch * 0.5)
    sp = math.sin(pitch * 0.5)
    cr = math.cos(roll * 0.5)
    sr = math.sin(roll * 0.5)

    w = cr * cp * cy + sr * sp * sy
    x = sr * cp * cy - cr * sp * sy
    y = cr * sp * cy + sr * cp * sy
    z = cr * cp * sy - sr * sp * cy
    return (w, x, y, z)


def quat_multiply(q1, q2):
    """Return the Hamilton product q1 * q2."""
    w1, x1, y1, z1 = q1
    w2, x2, y2, z2 = q2
    return (
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
        w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
    )


def format_quat(rpy: List[float]) -> str:
    """Return QML Qt.quaternion string for the given RPY angles in rad."""
    w, x, y, z = rpy_to_quat(rpy[0], rpy[1], rpy[2])
    return f"Qt.quaternion({w:.8f}, {x:.8f}, {y:.8f}, {z:.8f})"


def format_quat_with_offset(rpy: List[float], offset: Optional[List[float]] = None) -> str:
    """Return QML Qt.quaternion string with an optional RPY offset applied."""
    base = rpy_to_quat(rpy[0], rpy[1], rpy[2])
    if offset and any(offset):
        corr = rpy_to_quat(offset[0], offset[1], offset[2])
        base = quat_multiply(base, corr)
    return f"Qt.quaternion({base[0]:.8f}, {base[1]:.8f}, {base[2]:.8f}, {base[3]:.8f})"


def format_rgba(rgba: List[float]) -> str:
    """Return QML Qt.rgba string for the given RGBA color values."""
    # URDF colors are defined in the range [0, 1]
    r, g, b, a = (list(rgba) + [1.0, 1.0, 1.0, 1.0])[:4]
    return f"Qt.rgba({r:.6f}, {g:.6f}, {b:.6f}, {a:.6f})"


@dataclass
class Geometry:
    type: str = "node"  # mesh, box, cylinder, sphere
    mesh_file: str = ""
    size: List[float] = field(default_factory=list)
    mesh_scale: List[float] = field(default_factory=lambda: [1.0, 1.0, 1.0])
    mesh_unit_to_meter: float = 1.0


@dataclass
class Material:
    color: Optional[List[float]] = None
    texture: Optional[str] = None


@dataclass
class VisualOrCollision:
    geom: Geometry = field(default_factory=Geometry)
    xyz: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    rpy: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    material: Optional[Material] = None

    @property
    def rpy_deg(self) -> List[float]:
        return [math.degrees(v) for v in self.rpy]


@dataclass
class Inertial:
    mass: float = 0.0
    origin_xyz: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    origin_rpy: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    ixx: float = 0.0
    iyy: float = 0.0
    izz: float = 0.0
    ixy: float = 0.0
    ixz: float = 0.0
    iyz: float = 0.0


@dataclass
class Link:
    name: str
    visuals: List[VisualOrCollision] = field(default_factory=list)
    collisions: List[VisualOrCollision] = field(default_factory=list)
    inertial: Optional["Inertial"] = None


@dataclass
class JointLimit:
    lower: Optional[float] = None
    upper: Optional[float] = None
    effort: Optional[float] = None
    velocity: Optional[float] = None


@dataclass
class Joint:
    name: str
    type: str
    parent: str
    child: str
    axis: List[float] = field(default_factory=lambda: [1.0, 0.0, 0.0])
    xyz: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    rpy: List[float] = field(default_factory=lambda: [0.0, 0.0, 0.0])
    limit: Optional[JointLimit] = None

    @property
    def rpy_deg(self) -> List[float]:
        return [math.degrees(v) for v in self.rpy]


@dataclass
class RobotModel:
    name: str
    links: List[Link]
    joints: List[Joint]


@dataclass
class MeshAsset:
    module_name: str
    mesh_uri: str
    source_path: str


def _is_movable(j: Joint) -> bool:
    return j.type in ("revolute", "prismatic", "continuous")


def _movable_joints(model: "RobotModel") -> List[Joint]:
    return [j for j in model.joints if _is_movable(j)]


def _split_name_value_args(items: Optional[List[str]]) -> Dict[str, str]:
    mapping: Dict[str, str] = {}
    for item in items or []:
        if ":=" not in item:
            raise ValueError(f"Expected NAME:=VALUE, got '{item}'")
        key, value = item.split(":=", 1)
        key = key.strip()
        value = value.strip()
        if not key or not value:
            raise ValueError(f"Expected NAME:=VALUE, got '{item}'")
        mapping[key] = value
    return mapping


def normalize_package_map(items: Optional[List[str]]) -> Dict[str, str]:
    mapping = _split_name_value_args(items)
    resolved: Dict[str, str] = {}
    for package_name, package_root in mapping.items():
        package_root = os.path.abspath(package_root)
        if not os.path.isdir(package_root):
            raise RuntimeError(
                f"Package map path for '{package_name}' does not exist or is not a directory: "
                f"'{package_root}'"
            )
        resolved[package_name] = package_root
    return resolved


def _candidate_package_roots(package_name: str, base_path: str) -> List[str]:
    base = os.path.abspath(base_path)
    candidates = [
        base,
        os.path.join(base, package_name),
        os.path.join(base, "share", package_name),
    ]
    unique: List[str] = []
    for candidate in candidates:
        if not os.path.isdir(candidate):
            continue
        abs_candidate = os.path.abspath(candidate)
        if abs_candidate not in unique:
            unique.append(abs_candidate)
    return unique


def _mapped_package_dir(package_name: str, mapped_path: str) -> Optional[str]:
    for candidate in _candidate_package_roots(package_name, mapped_path):
        pkg_name = _read_package_name(candidate)
        if pkg_name == package_name:
            return candidate
    return None


def _mesh_visuals_exist(model: RobotModel) -> bool:
    for link in model.links:
        for visual in link.visuals:
            if visual.geom.type == "mesh" and visual.geom.mesh_file:
                return True
    return False


def _is_package_uri(uri: str) -> bool:
    return uri.startswith("package://")


def _split_package_uri(uri: str) -> Tuple[str, str]:
    if not _is_package_uri(uri):
        raise ValueError(f"Not a package URI: '{uri}'")
    rest = uri[len("package://") :]
    package, sep, rel_path = rest.partition("/")
    if not package or not sep or not rel_path:
        raise ValueError(f"Invalid package URI '{uri}', expected package://<name>/<path>")
    return package, rel_path


def _resolve_relpath_in_root(root_dir: str, rel_path: str) -> Optional[str]:
    """Resolve rel_path in root_dir with exact match first and case-insensitive fallbacks."""
    exact = os.path.abspath(os.path.join(root_dir, rel_path))
    if os.path.isfile(exact):
        return exact

    norm_rel = rel_path.strip("/\\")
    if not norm_rel:
        return None

    parent_rel = os.path.dirname(norm_rel)
    basename = os.path.basename(norm_rel)
    parent_dir = os.path.abspath(os.path.join(root_dir, parent_rel))
    if os.path.isdir(parent_dir):
        for entry in os.listdir(parent_dir):
            if entry.lower() == basename.lower():
                candidate = os.path.join(parent_dir, entry)
                if os.path.isfile(candidate):
                    return os.path.abspath(candidate)

    # Last resort inside package root: search by basename only.
    return _find_file_by_basename(root_dir, basename)


def _find_file_by_basename(root_dir: str, basename: str) -> Optional[str]:
    if not basename:
        return None
    candidates: List[Tuple[int, int, str, str]] = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower() != basename.lower():
                continue
            full_path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(full_path, root_dir)
            depth = rel_path.count(os.sep)
            candidates.append((depth, len(rel_path), rel_path, full_path))
    if not candidates:
        return None
    candidates.sort()
    return os.path.abspath(candidates[0][3])


def _resolve_package_uri(
    uri: str,
    *,
    urdf_path: str,
    package_map: Dict[str, str],
) -> Optional[str]:
    package_name, rel_path = _split_package_uri(uri)

    mapped_root = package_map.get(package_name)
    if mapped_root:
        for root_dir in _candidate_package_roots(package_name, mapped_root):
            resolved = _resolve_relpath_in_root(root_dir, rel_path)
            if resolved:
                return resolved

    ament_prefixes = [p for p in os.environ.get("AMENT_PREFIX_PATH", "").split(os.pathsep) if p]
    for prefix in ament_prefixes:
        resolved = _resolve_relpath_in_root(os.path.join(prefix, "share", package_name), rel_path)
        if resolved:
            return resolved
        # Some setups put package roots directly under prefix.
        resolved = _resolve_relpath_in_root(os.path.join(prefix, package_name), rel_path)
        if resolved:
            return resolved

    ros_package_paths = [p for p in os.environ.get("ROS_PACKAGE_PATH", "").split(os.pathsep) if p]
    for root in ros_package_paths:
        resolved = _resolve_relpath_in_root(os.path.join(root, package_name), rel_path)
        if resolved:
            return resolved

    basename = os.path.basename(rel_path)
    urdf_dir = os.path.dirname(os.path.abspath(urdf_path))
    return _find_file_by_basename(urdf_dir, basename)


def resolve_mesh_uri(
    mesh_uri: str,
    *,
    urdf_path: str,
    package_map: Dict[str, str],
) -> str:
    uri = mesh_uri.strip()
    if not uri:
        raise RuntimeError("Encountered an empty mesh URI")

    if uri.startswith("file://"):
        uri = uri[len("file://") :]

    if _is_package_uri(uri):
        resolved = _resolve_package_uri(uri, urdf_path=urdf_path, package_map=package_map)
        if resolved:
            return resolved
        raise RuntimeError(
            f"Could not resolve mesh URI '{mesh_uri}' via package map, ROS environment, "
            f"or URDF-directory fallback search."
        )

    if os.path.isabs(uri):
        if os.path.isfile(uri):
            return os.path.abspath(uri)
        raise RuntimeError(f"Mesh path does not exist: '{uri}'")

    urdf_dir = os.path.dirname(os.path.abspath(urdf_path))
    candidate = os.path.abspath(os.path.join(urdf_dir, uri))
    if os.path.isfile(candidate):
        return candidate

    fallback = _find_file_by_basename(urdf_dir, os.path.basename(uri))
    if fallback:
        return fallback

    raise RuntimeError(
        f"Could not resolve mesh URI '{mesh_uri}' relative to '{urdf_dir}' "
        f"or by basename fallback."
    )


def _tag_local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def _detect_dae_unit_to_meter(path: str) -> Tuple[Optional[float], Optional[str]]:
    try:
        tree = ET.parse(path)
    except Exception as exc:
        return None, f"failed to parse COLLADA XML: {exc}"

    root = tree.getroot()
    asset = next((elem for elem in root.iter() if _tag_local_name(elem.tag) == "asset"), None)
    if asset is None:
        return 1.0, None

    unit = next((elem for elem in asset if _tag_local_name(elem.tag) == "unit"), None)
    if unit is None:
        return 1.0, None

    meter_attr = unit.attrib.get("meter")
    if meter_attr is None or not str(meter_attr).strip():
        return 1.0, None
    try:
        meter = float(meter_attr)
    except ValueError:
        return None, f"invalid COLLADA unit meter='{meter_attr}'"
    if meter <= 0.0:
        return None, f"non-positive COLLADA unit meter='{meter_attr}'"
    return meter, None


def _detect_mesh_unit_to_meter(source_path: str) -> Tuple[Optional[float], Optional[str]]:
    ext = os.path.splitext(source_path)[1].lower()
    if ext in (".gltf", ".glb"):
        return 1.0, None
    if ext in (".dae", ".collada"):
        return _detect_dae_unit_to_meter(source_path)
    return None, f"unsupported mesh extension '{ext or '(none)'}'"


def apply_mesh_unit_policy(
    model: RobotModel,
    *,
    urdf_path: str,
    package_map: Dict[str, str],
    mesh_unit: str = "auto",
    mesh_unit_custom_to_meter: float = 1.0,
    mesh_default_unit: str = "meter",
    mesh_default_custom_to_meter: float = 1.0,
    warnings: Optional[List[str]] = None,
) -> None:
    """Resolve per-visual mesh unit scale in meters according to importer policy."""
    if mesh_unit != "auto":
        forced_factor = _mesh_unit_factor(mesh_unit, mesh_unit_custom_to_meter)
    else:
        forced_factor = None
    fallback_factor = _mesh_unit_factor(mesh_default_unit, mesh_default_custom_to_meter)

    issues = warnings if warnings is not None else []
    detected_by_uri: Dict[str, float] = {}

    for link in model.links:
        for visual in link.visuals:
            geom = visual.geom
            if geom.type != "mesh" or not geom.mesh_file:
                continue

            if forced_factor is not None:
                geom.mesh_unit_to_meter = forced_factor
                continue

            mesh_uri = geom.mesh_file
            if mesh_uri not in detected_by_uri:
                try:
                    source_path = resolve_mesh_uri(
                        mesh_uri,
                        urdf_path=urdf_path,
                        package_map=package_map,
                    )
                    detected_factor, detect_error = _detect_mesh_unit_to_meter(source_path)
                    if detected_factor is None:
                        detected_factor = fallback_factor
                        issues.append(
                            "[urdf2quick3d] Warning: mesh unit auto-detection failed "
                            f"for '{mesh_uri}' ({detect_error}); using fallback unit "
                            f"'{mesh_default_unit}' ({fallback_factor} m/unit)."
                        )
                except Exception as exc:
                    detected_factor = fallback_factor
                    issues.append(
                        "[urdf2quick3d] Warning: mesh unit auto-detection failed "
                        f"for '{mesh_uri}' ({exc}); using fallback unit "
                        f"'{mesh_default_unit}' ({fallback_factor} m/unit)."
                    )
                detected_by_uri[mesh_uri] = detected_factor

            geom.mesh_unit_to_meter = detected_by_uri[mesh_uri]


def collect_mesh_assets(
    model: RobotModel,
    *,
    urdf_path: str,
    package_map: Dict[str, str],
) -> List[MeshAsset]:
    """Collect mesh assets referenced by URDF visuals and resolve source file paths."""
    assets_by_module: Dict[str, MeshAsset] = {}
    for link in model.links:
        for visual in link.visuals:
            geom = visual.geom
            if geom.type != "mesh" or not geom.mesh_file:
                continue

            module_name = mesh_component_name(geom.mesh_file, link.name)
            source_path = resolve_mesh_uri(
                geom.mesh_file,
                urdf_path=urdf_path,
                package_map=package_map,
            )

            existing = assets_by_module.get(module_name)
            if existing is None:
                assets_by_module[module_name] = MeshAsset(
                    module_name=module_name,
                    mesh_uri=geom.mesh_file,
                    source_path=source_path,
                )
                continue

            if os.path.normcase(existing.source_path) != os.path.normcase(source_path):
                raise RuntimeError(
                    f"Module name collision for '{module_name}': '{existing.source_path}' and "
                    f"'{source_path}' are different files. Rename one mesh basename."
                )

    return list(assets_by_module.values())


# ---------------------- URDF Parsing ----------------------


def _needs_xacro(path: str) -> bool:
    if path.lower().endswith(".xacro"):
        return True
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if "<xacro:" in line:
                return True
    return False


def _find_package_root(path: str) -> Optional[str]:
    cur = os.path.abspath(path)
    if os.path.isfile(cur):
        cur = os.path.dirname(cur)
    while True:
        if os.path.isfile(os.path.join(cur, "package.xml")):
            return cur
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def _read_package_name(pkg_dir: str) -> Optional[str]:
    pkg_xml = os.path.join(pkg_dir, "package.xml")
    if not os.path.isfile(pkg_xml):
        return None
    try:
        tree = ET.parse(pkg_xml)
        root = tree.getroot()
        name = root.findtext("name")
        return name.strip() if name else None
    except Exception:
        return None


@contextmanager
def _ament_prefix_overlay(package_dirs: List[str]):
    if not package_dirs:
        yield None
        return
    with tempfile.TemporaryDirectory(prefix="urdf2quick3d_ament_") as prefix:
        share_dir = os.path.join(prefix, "share")
        os.makedirs(share_dir, exist_ok=True)
        index_dir = os.path.join(share_dir, "ament_index", "resource_index", "packages")
        os.makedirs(index_dir, exist_ok=True)
        for pkg_dir in package_dirs:
            pkg_dir = os.path.abspath(pkg_dir)
            pkg_name = _read_package_name(pkg_dir) or os.path.basename(pkg_dir)
            target = os.path.join(share_dir, pkg_name)
            if not os.path.exists(target):
                os.symlink(pkg_dir, target)
            marker = os.path.join(index_dir, pkg_name)
            if not os.path.exists(marker):
                with open(marker, "w", encoding="utf-8"):
                    pass
        yield prefix


@contextmanager
def _temp_environ(env_updates: Dict[str, str]):
    old: Dict[str, Optional[str]] = {}
    for key, value in env_updates.items():
        old[key] = os.environ.get(key)
        os.environ[key] = value
    try:
        yield
    finally:
        for key, value in old.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value


def _build_ament_env(ament_prefix: Optional[str]) -> Dict[str, str]:
    if not ament_prefix:
        return {}
    existing = os.environ.get("AMENT_PREFIX_PATH")
    if existing:
        return {"AMENT_PREFIX_PATH": ament_prefix + os.pathsep + existing}
    return {"AMENT_PREFIX_PATH": ament_prefix}


def _collect_xacro_packages(
    path: str,
    package_map: Optional[Dict[str, str]] = None,
) -> List[str]:
    packages: List[str] = []
    local_pkg = _find_package_root(path)
    if local_pkg:
        packages.append(os.path.abspath(local_pkg))
    for package_name, mapped_path in (package_map or {}).items():
        mapped_pkg_dir = _mapped_package_dir(package_name, mapped_path)
        if mapped_pkg_dir and mapped_pkg_dir not in packages:
            packages.append(mapped_pkg_dir)
    return packages



def _split_xacro_args(xacro_args: Optional[List[str]]) -> Tuple[List[str], Dict[str, str]]:
    cli_args: List[str] = []
    mappings: Dict[str, str] = {}
    for arg in xacro_args or []:
        cli_args.append(arg)
        if ":=" in arg:
            key, value = arg.split(":=", 1)
            if key:
                mappings[key] = value
    return cli_args, mappings


def _augment_xacro_error(message: str) -> str:
    lower = message.lower()
    hints: List[str] = []
    if "ament_index_python" in message or "substitution args not supported" in lower:
        hints.append(
            "Hint: source /opt/ros/<distro>/setup.bash and install "
            "ros-<distro>-ament-index-python."
        )
    if "invalid parameter" in lower:
        hints.append(
            "Hint: xacro macro argument mismatch. Ensure the turtlebot4_description "
            "package in your ROS environment matches the xacro files you are converting, "
            "or overlay the local package by sourcing its workspace."
        )
    if not hints:
        return message
    return message + "\n" + "\n".join(hints)


def _run_xacro_cli(
    path: str,
    xacro_args: Optional[List[str]] = None,
    env: Optional[Dict[str, str]] = None,
) -> Optional[str]:
    if shutil.which("xacro") is None:
        return None
    cmd = ["xacro", path]
    if xacro_args:
        cmd.extend(xacro_args)
    try:
        result = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
        )
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip()
        msg = stderr or str(exc)
        msg = _augment_xacro_error(msg)
        raise RuntimeError(f"xacro failed for '{path}': {msg}") from exc
    return result.stdout


def _process_xacro(
    path: str,
    xacro_args: Optional[List[str]] = None,
    package_map: Optional[Dict[str, str]] = None,
) -> str:
    cli_args, mappings = _split_xacro_args(xacro_args)
    packages = _collect_xacro_packages(path, package_map=package_map)
    py_exc: Optional[Exception] = None
    with _ament_prefix_overlay(packages) as prefix:
        env_updates = _build_ament_env(prefix)
        env = os.environ.copy()
        env.update(env_updates)
        with _temp_environ(env_updates):
            try:
                import xacro
                try:
                    if mappings:
                        return xacro.process_file(path, mappings=mappings).toxml()
                    return xacro.process_file(path).toxml()
                except Exception as exc:
                    py_exc = exc
            except ImportError as exc:
                py_exc = exc

        xml = _run_xacro_cli(path, cli_args, env=env)
        if xml is not None:
            return xml

    raise RuntimeError(
        f"xacro failed for '{path}': {py_exc}"
    ) from py_exc


def parse_urdf(
    path: str,
    xacro_args: Optional[List[str]] = None,
    package_map: Optional[Dict[str, str]] = None,
) -> RobotModel:
    if _needs_xacro(path):
        xml = _process_xacro(path, xacro_args=xacro_args, package_map=package_map)
        robot = URDF.from_xml_string(xml)
    else:
        robot = URDF.from_xml_file(path)
    model = RobotModel(name=robot.name or "robot", links=[], joints=[])

    # Collect named materials defined at the robot level so they can be
    # referenced later via <material name="foo"/> tags.  Each entry is stored
    # as our local Material dataclass for ease of use.
    material_map: Dict[str, Material] = {}
    for m in getattr(robot, "materials", []) or []:
        color = None
        if getattr(m, "color", None) is not None:
            if isinstance(m.color, (list, tuple)):
                color = list(m.color)
            elif getattr(m.color, "rgba", None) is not None:
                color = list(m.color.rgba)
        texture = m.texture.filename if getattr(m, "texture", None) else None
        if m.name:
            material_map[m.name] = Material(color=color, texture=texture)

    for link in robot.links:
        visuals: List[VisualOrCollision] = []
        for visual in getattr(link, "visuals", []) or []:
            v = VisualOrCollision()
            if visual.origin is not None:
                v.xyz = visual.origin.xyz or [0.0, 0.0, 0.0]
                v.rpy = visual.origin.rpy or [0.0, 0.0, 0.0]
            geom_obj = visual.geometry
            g = Geometry()
            if isinstance(geom_obj, Mesh):
                g.type = "mesh"
                g.mesh_file = geom_obj.filename or ""
                g.mesh_scale = _normalize_mesh_scale(getattr(geom_obj, "scale", None))
            elif isinstance(geom_obj, Box):
                g.type = "box"
                g.size = list(geom_obj.size or [0.0, 0.0, 0.0])
            elif isinstance(geom_obj, Cylinder):
                g.type = "cylinder"
                g.size = [float(geom_obj.radius or 0.0), float(geom_obj.length or 0.0)]
                # Qt Quick 3D cylinders are Y-up; adjust orientation once here
                v.rpy[0] += math.pi / 2
            elif isinstance(geom_obj, Sphere):
                g.type = "sphere"
                g.size = [float(geom_obj.radius or 0.0)]
            v.geom = g
            if getattr(visual, "material", None) is not None and g.type != "mesh":
                mat = visual.material
                color = None
                texture = None

                # If the material element defines color/texture inline, use it
                if getattr(mat, "color", None) is not None or getattr(mat, "texture", None) is not None:
                    if getattr(mat, "color", None) is not None:
                        if isinstance(mat.color, (list, tuple)):
                            color = list(mat.color)
                        elif getattr(mat.color, "rgba", None) is not None:
                            color = list(mat.color.rgba)
                    texture = mat.texture.filename if getattr(mat, "texture", None) else None
                    v.material = Material(color=color, texture=texture)
                    # Store named materials for potential alias references
                    if getattr(mat, "name", None):
                        material_map[mat.name] = v.material
                # Otherwise try to resolve a named material alias
                elif getattr(mat, "name", None) and mat.name in material_map:
                    v.material = material_map[mat.name]
            visuals.append(v)
        if not visuals:
            visuals.append(VisualOrCollision())

        # --- collision shapes ---
        collisions: List[VisualOrCollision] = []
        for coll in getattr(link, "collisions", []) or []:
            c = VisualOrCollision()
            if coll.origin is not None:
                c.xyz = list(coll.origin.xyz or [0.0, 0.0, 0.0])
                c.rpy = list(coll.origin.rpy or [0.0, 0.0, 0.0])
            geom_obj = coll.geometry
            g = Geometry()
            if isinstance(geom_obj, Mesh):
                g.type = "mesh"
                g.mesh_file = geom_obj.filename or ""
                g.mesh_scale = _normalize_mesh_scale(getattr(geom_obj, "scale", None))
            elif isinstance(geom_obj, Box):
                g.type = "box"
                g.size = list(geom_obj.size or [0.0, 0.0, 0.0])
            elif isinstance(geom_obj, Cylinder):
                g.type = "cylinder"
                g.size = [float(geom_obj.radius or 0.0), float(geom_obj.length or 0.0)]
                # CapsuleShape aligns along Y; match the visual cylinder convention
                c.rpy[0] += math.pi / 2
            elif isinstance(geom_obj, Sphere):
                g.type = "sphere"
                g.size = [float(geom_obj.radius or 0.0)]
            c.geom = g
            collisions.append(c)

        # --- inertial ---
        inertial: Optional[Inertial] = None
        if getattr(link, "inertial", None) is not None:
            raw = link.inertial
            inertial = Inertial(
                mass=float(raw.mass or 0.0),
            )
            if raw.origin is not None:
                inertial.origin_xyz = list(raw.origin.xyz or [0.0, 0.0, 0.0])
                inertial.origin_rpy = list(raw.origin.rpy or [0.0, 0.0, 0.0])
            if raw.inertia is not None:
                inertial.ixx = float(getattr(raw.inertia, "ixx", 0.0) or 0.0)
                inertial.iyy = float(getattr(raw.inertia, "iyy", 0.0) or 0.0)
                inertial.izz = float(getattr(raw.inertia, "izz", 0.0) or 0.0)
                inertial.ixy = float(getattr(raw.inertia, "ixy", 0.0) or 0.0)
                inertial.ixz = float(getattr(raw.inertia, "ixz", 0.0) or 0.0)
                inertial.iyz = float(getattr(raw.inertia, "iyz", 0.0) or 0.0)

        model.links.append(Link(
            name=link.name,
            visuals=visuals,
            collisions=collisions,
            inertial=inertial,
        ))

    for joint in robot.joints:
        j = Joint(
            name=joint.name or "",
            type=joint.type or "",
            parent=joint.parent or "",
            child=joint.child or "",
            axis=list(joint.axis) if joint.axis is not None else [1.0, 0.0, 0.0],
            xyz=list(joint.origin.xyz) if joint.origin is not None and joint.origin.xyz is not None else [0.0, 0.0, 0.0],
            rpy=list(joint.origin.rpy) if joint.origin is not None and joint.origin.rpy is not None else [0.0, 0.0, 0.0],
        )
        if joint.limit is not None:
            j.limit = JointLimit(
                lower=joint.limit.lower if joint.limit.lower is not None else None,
                upper=joint.limit.upper if joint.limit.upper is not None else None,
                effort=joint.limit.effort if joint.limit.effort is not None else None,
                velocity=joint.limit.velocity if joint.limit.velocity is not None else None,
            )
        model.joints.append(j)

    return model


# -------------------- Tree building -----------------------


@dataclass
class TreeNode:
    link: Link
    joint: Optional[Joint] = None  # inbound joint
    children: List["TreeNode"] = field(default_factory=list)
    synthetic: bool = False


def build_tree(model: RobotModel) -> Optional[TreeNode]:
    nodes: Dict[str, TreeNode] = {link.name: TreeNode(link=link) for link in model.links}
    child_links = set()
    for j in model.joints:
        parent = nodes.get(j.parent)
        child = nodes.get(j.child)
        if not parent or not child:
            continue
        child.joint = j
        parent.children.append(child)
        child_links.add(child.link.name)
    roots = [n for n in nodes.values() if n.link.name not in child_links]
    if not roots:
        return None
    if len(roots) == 1:
        return roots[0]

    existing_ids = {qml_id(link.name) for link in model.links}
    base_name = "__virtual_root__"
    name = base_name
    idx = 1
    while qml_id(name) in existing_ids:
        idx += 1
        name = f"{base_name}_{idx}"
    root_link = Link(name=name, visuals=[])
    return TreeNode(link=root_link, children=roots, synthetic=True)


# -------------------- QML generation ----------------------


def collect_root_props(node: TreeNode, props: List[str]):
    """Collect property names for movable joints"""
    if node.joint and node.joint.type in ("revolute", "prismatic", "continuous"):
        props.append(joint_prop_name(node.joint))
    for c in node.children:
        collect_root_props(c, props)


def collect_aliases(node: TreeNode, out: List[str]):
    """Collect scenePosition aliases for every link"""
    if not node.synthetic:
        prop_name = to_camel_case(node.link.name) + "Position"
        out.append(
            f"readonly property alias {prop_name}: {qml_id(node.link.name)}.scenePosition"
        )
    for c in node.children:
        collect_aliases(c, out)


def collect_component_plugins(model: RobotModel) -> List[str]:
    """Return plugin target names for mesh components used by the model."""
    plugins: List[str] = []
    for link in model.links:
        for v in link.visuals:
            g = v.geom
            if g.type == "mesh" and g.mesh_file:
                type_name = mesh_component_name(g.mesh_file, link.name)
                target = f"Generated_QtQuick3D_{type_name}plugin"
                if target not in plugins:
                    plugins.append(target)
    return plugins


def _resolve_executable_path(executable: str) -> Optional[str]:
    if os.path.sep in executable or (os.path.altsep and os.path.altsep in executable):
        candidate = os.path.abspath(executable)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
        return None
    return shutil.which(executable)


def _default_repo_license_source() -> Optional[str]:
    """Return the repository LICENSE file path when available."""
    module_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(os.path.dirname(module_dir))
    candidate = os.path.join(repo_root, "LICENSE")
    if os.path.isfile(candidate):
        return candidate
    return None


def copy_license_source_to_output(license_source: str, output_dir: str) -> List[str]:
    """Copy a license file or directory into an output directory."""
    source_path = os.path.abspath(license_source)
    output_dir = os.path.abspath(output_dir)
    if not os.path.exists(source_path):
        raise RuntimeError(f"License source does not exist: '{source_path}'")

    os.makedirs(output_dir, exist_ok=True)

    if os.path.isfile(source_path):
        destination = os.path.join(output_dir, os.path.basename(source_path))
        if os.path.abspath(destination) != source_path:
            shutil.copy2(source_path, destination)
        return [destination]

    if not os.path.isdir(source_path):
        raise RuntimeError(f"License source must be a file or directory: '{source_path}'")

    destination = os.path.join(output_dir, "LicensingFiles")

    if os.path.abspath(destination) == source_path:
        raise RuntimeError(
            f"License source '{source_path}' cannot be copied into itself."
        )

    if os.path.isdir(destination):
        shutil.rmtree(destination)
    shutil.copytree(source_path, destination)
    return [destination]


def _list_generated_qtquick3d_modules(qtquick3d_dir: str) -> List[str]:
    modules: List[str] = []
    if not os.path.isdir(qtquick3d_dir):
        return modules
    for name in sorted(os.listdir(qtquick3d_dir)):
        module_dir = os.path.join(qtquick3d_dir, name)
        if not os.path.isdir(module_dir):
            continue
        module_qml = os.path.join(module_dir, f"{name}.qml")
        if os.path.isfile(module_qml):
            modules.append(name)
    return modules


def _collision_shape_params(
    coll: "VisualOrCollision",
    *,
    scene_units_per_meter: float = 100.0,
) -> Optional[Dict[str, Any]]:
    """Return a dict describing the QtQuick3DPhysics shape for a collision element,
    or None if the geometry is a mesh (shapes must be added manually by the user).

    Keys returned:
      shape_type    – QML type name, e.g. "BoxShape"
      extents       – [x, y, z] in scene units; only set for BoxShape
      diameter      – float in scene units; set for SphereShape / CapsuleShape
      height        – float in scene units; set for CapsuleShape (None for SphereShape)
      origin_xyz    – [x, y, z] offset in scene units
      origin_rpy    – [roll, pitch, yaw] radians (already adjusted for cylinder Y-up)
    """
    g = coll.geom
    spm = scene_units_per_meter
    origin_xyz = [v * spm for v in coll.xyz]
    origin_rpy = list(coll.rpy)

    if g.type == "box":
        return {
            "shape_type": "BoxShape",
            "extents": [g.size[0] * spm, g.size[1] * spm, g.size[2] * spm],
            "diameter": None,
            "height": None,
            "origin_xyz": origin_xyz,
            "origin_rpy": origin_rpy,
        }
    if g.type == "sphere":
        return {
            "shape_type": "SphereShape",
            "extents": None,
            "diameter": g.size[0] * 2.0 * spm,
            "height": None,
            "origin_xyz": origin_xyz,
            "origin_rpy": origin_rpy,
        }
    if g.type == "cylinder":
        # URDF size = [radius, length]; rpy[0] already +π/2 from parsing
        return {
            "shape_type": "CapsuleShape",
            "extents": None,
            "diameter": g.size[0] * 2.0 * spm,
            "height": g.size[1] * spm,
            "origin_xyz": origin_xyz,
            "origin_rpy": origin_rpy,
        }
    # Mesh geometry: collision shape must be added manually in a visual editor.
    return None


def _make_env(**kwargs) -> Environment:
    """Return a Jinja2 Environment backed by the co-located *templates/urdfviewer/* directory."""
    templates_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates", "urdfviewer")
    env = Environment(
        loader=FileSystemLoader(templates_dir),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
        **kwargs,
    )
    env.filters["basename"] = lambda path: os.path.basename(path)
    env.filters["splitext0"] = lambda name: os.path.splitext(name)[0]
    env.filters["joint_prop_name"] = joint_prop_name
    env.filters["capitalize_first"] = capitalize_first
    env.filters["mesh_component"] = mesh_component_name
    env.filters["qt_quat"] = format_quat
    env.filters["qt_quat_with_offset"] = format_quat_with_offset
    env.filters["qt_rgba"] = format_rgba
    env.filters["qml_id"] = qml_id

    def _collision_shapes_filter(
        link: "Link",
        scene_units_per_meter: float = 100.0,
    ) -> List[Dict[str, Any]]:
        return [
            s for s in (
                _collision_shape_params(c, scene_units_per_meter=scene_units_per_meter)
                for c in link.collisions
            )
            if s is not None
        ]

    env.filters["collision_shapes"] = _collision_shapes_filter
    return env


def generate_generated_root_cmake() -> str:
    return (
        "### This file is automatically generated by Qt Design Studio.\n"
        "### Do not change\n\n"
        "add_subdirectory(QtQuick3D)\n"
    )


def generate_generated_note() -> str:
    return "Imported 3D assets and components imported from bundles will be created in this folder.\n"


def generate_generated_qtquick3d_cmake(modules: List[str]) -> str:
    return _make_env().get_template("generated_qtquick3d.cmake").render(modules=modules)


def write_generated_scaffolding(generated_dir: str, modules: List[str]) -> None:
    qtquick3d_dir = os.path.join(generated_dir, "QtQuick3D")
    os.makedirs(qtquick3d_dir, exist_ok=True)

    with open(os.path.join(generated_dir, "Generated.txt"), "w", encoding="utf-8") as f:
        f.write(generate_generated_note())
    with open(os.path.join(generated_dir, "CMakeLists.txt"), "w", encoding="utf-8") as f:
        f.write(generate_generated_root_cmake())
    with open(os.path.join(qtquick3d_dir, "CMakeLists.txt"), "w", encoding="utf-8") as f:
        f.write(generate_generated_qtquick3d_cmake(modules))


def _run_balsam_import(
    *,
    balsam_exe: str,
    source_path: str,
    output_dir: str,
    balsam_options: Optional[List[str]] = None,
    timeout_sec: int = 300,
) -> None:
    cmd = [balsam_exe]
    cmd.extend([opt for opt in (balsam_options or []) if opt])
    cmd.extend(["--outputPath", output_dir, source_path])

    try:
        subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout_sec,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(
            f"Balsam timed out after {timeout_sec}s for '{source_path}'"
        ) from exc
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        stdout = (exc.stdout or "").strip()
        detail = stderr or stdout or str(exc)
        raise RuntimeError(f"Balsam import failed for '{source_path}': {detail}") from exc


def write_generated_module_qmldir(module_dir: str, module_name: str) -> None:
    qmldir_path = os.path.join(module_dir, "qmldir")
    qmldir_contents = (
        f"module Generated.QtQuick3D.{module_name}\n"
        f"{module_name} 1.0 {module_name}.qml\n"
    )
    with open(qmldir_path, "w", encoding="utf-8") as f:
        f.write(qmldir_contents)


def generate_mesh_assets_with_balsam(
    model: RobotModel,
    *,
    urdf_path: str,
    robot_dir: str,
    package_map: Dict[str, str],
    balsam_bin: str = "balsam",
    balsam_options: Optional[List[str]] = None,
    balsam_timeout: int = 300,
) -> List[str]:
    """Generate Generated/QtQuick3D modules for mesh visuals using Balsam."""
    assets = collect_mesh_assets(model, urdf_path=urdf_path, package_map=package_map)
    if not assets:
        return []

    balsam_exe = _resolve_executable_path(balsam_bin)
    if not balsam_exe:
        raise RuntimeError(
            f"Balsam executable '{balsam_bin}' was not found or is not executable."
        )

    generated_dir = os.path.join(robot_dir, "Generated")
    qtquick3d_dir = os.path.join(generated_dir, "QtQuick3D")
    os.makedirs(qtquick3d_dir, exist_ok=True)

    for asset in assets:
        module_dir = os.path.join(qtquick3d_dir, asset.module_name)
        if os.path.isdir(module_dir):
            shutil.rmtree(module_dir)
        os.makedirs(module_dir, exist_ok=True)
        print(
            f"[urdf2quick3d] Balsam import: '{asset.mesh_uri}' -> "
            f"'Generated/QtQuick3D/{asset.module_name}'"
        )
        _run_balsam_import(
            balsam_exe=balsam_exe,
            source_path=asset.source_path,
            output_dir=module_dir,
            balsam_options=balsam_options,
            timeout_sec=balsam_timeout,
        )
        expected_qml = os.path.join(module_dir, f"{asset.module_name}.qml")
        if not os.path.isfile(expected_qml):
            qml_candidates = [
                name
                for name in os.listdir(module_dir)
                if name.lower().endswith(".qml") and os.path.isfile(os.path.join(module_dir, name))
            ]
            if len(qml_candidates) == 1:
                os.replace(
                    os.path.join(module_dir, qml_candidates[0]),
                    expected_qml,
                )
            elif not qml_candidates:
                raise RuntimeError(
                    f"Balsam import succeeded but no QML file was generated in '{module_dir}'"
                )
            else:
                raise RuntimeError(
                    f"Balsam generated multiple QML files for '{asset.source_path}': "
                    f"{', '.join(sorted(qml_candidates))}"
                )
        write_generated_module_qmldir(module_dir, asset.module_name)

    modules = _list_generated_qtquick3d_modules(qtquick3d_dir)
    write_generated_scaffolding(generated_dir, modules)
    return modules


def generate_qml(
    model: RobotModel,
    scene_units_per_meter: float = 100.0,
    instance_scale: float = 1.0,
    indent: str = "    ",
    module_prefix: str = "Generated.QtQuick3D.",
    axis_transform: bool = True,
    mesh_rotation: Optional[List[float]] = None,
    physics: bool = False,
) -> str:
    root = build_tree(model)
    if not root:
        return ""
    if mesh_rotation is None:
        mesh_rotation = [0.0, 0.0, 0.0]
    zero_rpy = [0.0, 0.0, 0.0]

    components = []
    for link in model.links:
        for v in link.visuals:
            g = v.geom
            if g.type == "mesh" and g.mesh_file:
                type_name = mesh_component_name(g.mesh_file, link.name)
                import_name = module_prefix + type_name
                if import_name not in components:
                    components.append(import_name)
    base_name = to_pascal_case(model.name)
    control_decl = f"required property {base_name}Control control"

    aliases: List[str] = []
    collect_aliases(root, aliases)

    env = _make_env()
    template = env.get_template("robot_model.qml")

    return template.render(
        root=root,
        components=components,
        aliases=aliases,
        control_decl=control_decl,
        indent=indent,
        scene_units_per_meter=scene_units_per_meter,
        instance_scale=instance_scale,
        axis_transform=axis_transform,
        mesh_rotation=mesh_rotation,
        zero_rpy=zero_rpy,
        pi=math.pi,
        physics=physics,
    )


def write_qml(
    model: RobotModel,
    path: str,
    *,
    header_comment: Optional[str] = None,
    **kwargs,
) -> None:
    qml = generate_qml(model, **kwargs)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_qmldir(base_name: str) -> str:
    """Return qmldir file contents for the robot model module."""
    return f"{base_name} 1.0 {base_name}.qml\n"


def generate_control_qmldir(base_name: str) -> str:
    """Return qmldir file contents for the control module."""
    return f"module RobotControl.{base_name}\n"


def write_qmldir(base_name: str, path: str, *, header_comment: Optional[str] = None) -> None:
    qmldir = generate_qmldir(base_name)
    if header_comment:
        qmldir = f"# {header_comment}\n" + qmldir
    with open(path, "w", encoding="utf-8") as f:
        f.write(qmldir)


def generate_control_qml(
    model: RobotModel,
    *,
    load_from_json: bool = False,
    scale: Optional[float] = None,
) -> str:
    """Return a QML file providing the same properties as the C++ control class."""
    _ = scale
    props = [joint_prop_name(j) for j in _movable_joints(model)]
    joints_name = model.name
    joint_infos = collect_joint_metadata(model)
    return _make_env().get_template("control.qml").render(
        props=props,
        joints_name=joints_name,
        joint_infos=joint_infos,
        load_from_json=load_from_json,
    )


def write_control_qml(
    model: RobotModel,
    out_dir: str,
    *,
    load_from_json: bool = False,
    scale: Optional[float] = None,
    header_comment: Optional[str] = None,
) -> None:
    """Write the QML file exposing control properties."""
    qml_path = os.path.join(out_dir, f"{to_pascal_case(model.name)}Control.qml")
    qml = generate_control_qml(model, load_from_json=load_from_json, scale=scale)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_control_panel_qml() -> str:
    """Return a QML file implementing a simple joint control panel."""
    return _make_env().get_template("control_panel.qml").render()


def write_control_panel_qml(base_name: str, out_dir: str, *, header_comment: Optional[str] = None) -> None:
    """Write the QML control panel file."""
    qml_path = os.path.join(out_dir, "ControlPanel.qml")
    qml = generate_control_panel_qml()
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)
 

def write_control_qmldir(base_name: str, out_dir: str, *, header_comment: Optional[str] = None) -> None:
    """Write the qmldir file for the control module."""
    qmldir_path = os.path.join(out_dir, "qmldir")
    qmldir = generate_control_qmldir(base_name)
    if header_comment:
        qmldir = f"# {header_comment}\n" + qmldir
    with open(qmldir_path, "w", encoding="utf-8") as f:
        f.write(qmldir)


def generate_preview_scene_qml(base_name: str, *, physics: bool = False) -> str:
    """Return an embeddable QML scene for previewing the generated robot model."""
    return _make_env().get_template("preview_scene.qml").render(
        base_name=base_name, physics=physics
    )


def write_preview_scene_qml(
    base_name: str,
    out_dir: str,
    *,
    physics: bool = False,
    header_comment: Optional[str] = None,
) -> None:
    """Write the embeddable preview scene QML file."""
    qml_path = os.path.join(out_dir, "PreviewScene.qml")
    qml = generate_preview_scene_qml(base_name, physics=physics)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_ros_preview_scene_qml(
    base_name: str,
    model: "RobotModel",
    joint_states_topic: str = "/joint_states",
) -> str:
    """Return a QML scene that drives the robot live from /joint_states via qt-ros2-bridge."""
    joint_map = [
        {"ros_name": j.name, "qml_prop": joint_prop_name(j)}
        for j in _movable_joints(model)
    ]
    return _make_env().get_template("ros_preview_scene.qml").render(
        base_name=base_name,
        joint_states_topic=joint_states_topic,
        joint_map=joint_map,
    )


def write_ros_preview_scene_qml(
    base_name: str,
    model: "RobotModel",
    out_dir: str,
    *,
    joint_states_topic: str = "/joint_states",
    header_comment: Optional[str] = None,
) -> None:
    """Write RosPreviewScene.qml — a live ROS-bridge-connected scene."""
    qml_path = os.path.join(out_dir, "RosPreviewScene.qml")
    qml = generate_ros_preview_scene_qml(base_name, model, joint_states_topic)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_ros_main_qml(base_name: str) -> str:
    """Return a standalone Window QML that wraps RosPreviewScene."""
    return _make_env().get_template("ros_main.qml").render(base_name=base_name)


def write_ros_main_qml(
    base_name: str,
    out_dir: str,
    *,
    header_comment: Optional[str] = None,
) -> None:
    """Write RosMain.qml — a standalone window for the ROS-bridge preview."""
    qml_path = os.path.join(out_dir, "RosMain.qml")
    qml = generate_ros_main_qml(base_name)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_preview_qml(base_name: str) -> str:
    """Return the standalone preview window QML that wraps PreviewScene."""
    return _make_env().get_template("preview_main.qml").render(base_name=base_name)


def write_preview_qml(
    base_name: str,
    out_dir: str,
    *,
    header_comment: Optional[str] = None,
) -> None:
    """Write the standalone preview window QML file."""
    qml_path = os.path.join(out_dir, "Main.qml")
    qml = generate_preview_qml(base_name)
    if header_comment:
        qml = f"// {header_comment}\n" + qml
    with open(qml_path, "w", encoding="utf-8") as f:
        f.write(qml)


def generate_main_cpp(base_name: str) -> str:
    """Return C++ main() source for the standalone robot preview executable."""
    return _make_env().get_template("main.cpp").render(base_name=base_name)


def write_main_cpp(
    base_name: str,
    out_dir: str,
    *,
    header_comment: Optional[str] = None,
) -> None:
    """Write main.cpp for the standalone robot preview executable."""
    path = os.path.join(out_dir, "main.cpp")
    cpp = generate_main_cpp(base_name)
    if header_comment:
        cpp = f"// {header_comment}\n" + cpp
    with open(path, "w", encoding="utf-8") as f:
        f.write(cpp)


def generate_qmlproject(base_name: str) -> str:
    """Return a qmlproject file for previewing the robot model."""
    return _make_env().get_template("robot.qmlproject").render(base_name=base_name)


def write_qmlproject(
    base_name: str,
    out_dir: str,
    *,
    header_comment: Optional[str] = None,
) -> None:
    """Write the qmlproject file."""
    qmlproject_path = os.path.join(out_dir, f"{base_name}.qmlproject")
    qmlproject = generate_qmlproject(base_name)
    if header_comment:
        qmlproject = f"// {header_comment}\n" + qmlproject
    with open(qmlproject_path, "w", encoding="utf-8") as f:
        f.write(qmlproject)


def generate_control_base_h(model: RobotModel, load_from_json: bool = False) -> str:
    """Generate C++ header for the auto-generated base control class."""
    movable = _movable_joints(model)
    joints_enumerated = [
        (idx, j, joint_prop_name(j), capitalize_first(joint_prop_name(j)))
        for idx, j in enumerate(movable)
    ]
    guard = f"{model.name.upper()}_CONTROL_BASE_H"
    return _make_env().get_template("control_base.h").render(
        cls=to_pascal_case(model.name),
        joints_enumerated=joints_enumerated,
        guard=guard,
    )


def generate_control_base_cpp(
    model: RobotModel,
    header_name: str,
    scale: Optional[float] = None,
    load_from_json: bool = False,
) -> str:
    """Generate C++ source implementing the base control class."""
    _ = scale
    movable = _movable_joints(model)
    joints_enumerated = [
        (idx, j, joint_prop_name(j), capitalize_first(joint_prop_name(j)))
        for idx, j in enumerate(movable)
    ]
    joint_infos = collect_joint_metadata(model)
    qml_name = to_pascal_case(model.name)
    qml_uri_path = f"{qml_name}/Model"
    return _make_env().get_template("control_base.cpp").render(
        cls=to_pascal_case(model.name),
        joints_enumerated=joints_enumerated,
        header=header_name,
        joints=movable,
        joint_infos=joint_infos,
        load_from_json=load_from_json,
        qml_uri_path=qml_uri_path,
        qml_name=qml_name,
        name=model.name,
    )


def generate_control_stub_h(model: RobotModel) -> str:
    """Generate C++ header for the user-editable control class."""
    guard = f"{model.name.upper()}_CONTROL_H"
    return _make_env().get_template("control_stub.h").render(
        cls=to_pascal_case(model.name),
        base_header=f"{to_pascal_case(model.name)}ControlBase.h",
        guard=guard,
    )


def generate_control_stub_cpp(model: RobotModel, header_name: str) -> str:
    """Generate C++ source for the user-editable control class."""
    return _make_env().get_template("control_stub.cpp").render(
        cls=to_pascal_case(model.name),
        header=header_name,
    )


def write_control_files(
    model: RobotModel,
    base_header_path: str,
    base_source_path: str,
    control_header_path: str,
    control_source_path: str,
    scale: Optional[float] = None,
    load_from_json: bool = False,
    header_comment: Optional[str] = None,
) -> None:
    _ = scale
    base_header = generate_control_base_h(model, load_from_json=load_from_json)
    base_source = generate_control_base_cpp(
        model,
        os.path.basename(base_header_path),
        load_from_json=load_from_json,
    )
    if header_comment:
        base_header = f"// {header_comment}\n" + base_header
        base_source = f"// {header_comment}\n" + base_source
    with open(base_header_path, "w", encoding="utf-8") as h:
        h.write(base_header)
    with open(base_source_path, "w", encoding="utf-8") as c:
        c.write(base_source)

    if not os.path.exists(control_header_path):
        control_header = generate_control_stub_h(model)
        with open(control_header_path, "w", encoding="utf-8") as h:
            h.write(control_header)
    if not os.path.exists(control_source_path):
        control_source = generate_control_stub_cpp(
            model,
            os.path.basename(control_header_path),
        )
        with open(control_source_path, "w", encoding="utf-8") as c:
            c.write(control_source)


def collect_joint_metadata(model: RobotModel, scale: Optional[float] = None) -> List[Dict]:
    """Return joint limits and axes as dictionaries suitable for QML."""
    _ = scale
    joints = []
    for j in model.joints:
        if j.type == "fixed":
            continue 

        lower = None
        upper = None
        if j.limit:
            lower = j.limit.lower
            upper = j.limit.upper

        if j.type == "revolute":
            pass  # limits are already in radians per the URDF spec
        elif j.type == "continuous":
            lower = 0.0
            upper = 2 * math.pi

        jprop = joint_prop_name(j)

        joints.append({
            "name": jprop,
            "type": j.type,
            "axis": j.axis,
            "lower": lower,
            "upper": upper,
        })

    return joints


def write_joint_metadata(model: RobotModel, path: str, scale: Optional[float] = None) -> None:
    """Export joint limits and axes to a JSON file."""
    joints = collect_joint_metadata(model, scale=scale)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(joints, f, indent=2)


def generate_control_cmake(base_name: str, joints_name: str) -> str:
    """Generate a CMakeLists.txt for the control module."""
    return _make_env().get_template("control.cmake").render(
        base_name=base_name,
        joints_name=joints_name,
    )


def write_control_cmake_file(
    path: str,
    base_name: str,
    joints_name: str,
    *,
    header_comment: Optional[str] = None,
) -> None:
    cmake = generate_control_cmake(base_name, joints_name)
    if header_comment:
        cmake = f"# {header_comment}\n" + cmake
    with open(path, "w", encoding="utf-8") as f:
        f.write(cmake)


def generate_model_cmake(
    base_name: str,
    component_plugins: List[str],
    joints_name: str,
    *,
    ros_bridge: bool = False,
    physics: bool = False,
) -> str:
    """Generate CMakeLists.txt for the robot model module."""
    return _make_env().get_template("model.cmake").render(
        base_name=base_name,
        plugins=component_plugins,
        joints_name=joints_name,
        ros_bridge=ros_bridge,
        physics=physics,
    )


def write_model_cmake_file(
    path: str,
    base_name: str,
    component_plugins: List[str],
    joints_name: str,
    *,
    ros_bridge: bool = False,
    physics: bool = False,
    header_comment: Optional[str] = None,
) -> None:
    cmake = generate_model_cmake(base_name, component_plugins, joints_name,
                                 ros_bridge=ros_bridge, physics=physics)
    if header_comment:
        cmake = f"# {header_comment}\n" + cmake
    with open(path, "w", encoding="utf-8") as f:
        f.write(cmake)


def generate_robot_cmake(
    base_name: str,
    component_plugins: List[str],
    joints_name: str,
    *,
    ros_bridge: bool = False,
    physics: bool = False,
) -> str:
    """Generate the top-level CMakeLists.txt for the robot."""
    return generate_model_cmake(base_name, component_plugins, joints_name,
                                ros_bridge=ros_bridge, physics=physics)


def write_robot_cmake_file(
    path: str,
    base_name: str,
    component_plugins: List[str],
    joints_name: str,
    *,
    ros_bridge: bool = False,
    physics: bool = False,
    header_comment: Optional[str] = None,
) -> None:
    cmake = generate_robot_cmake(base_name, component_plugins, joints_name,
                                 ros_bridge=ros_bridge, physics=physics)
    if header_comment:
        cmake = f"# {header_comment}\n" + cmake
    with open(path, "w", encoding="utf-8") as f:
        f.write(cmake)


def _xacro_arg(value: str) -> str:
    if ":=" not in value or value.startswith(":=") or value.endswith(":="):
        raise argparse.ArgumentTypeError("Expected NAME:=VALUE")
    return value


def _name_value_arg(value: str) -> str:
    if ":=" not in value or value.startswith(":=") or value.endswith(":="):
        raise argparse.ArgumentTypeError("Expected NAME:=VALUE")
    return value


def _create_argument_parser() -> argparse.ArgumentParser:
    default_license_source = _default_repo_license_source()

    parser = argparse.ArgumentParser(description="Convert URDF to QML using Jinja")
    parser.add_argument("urdf", help="Input URDF file")
    parser.add_argument(
        "dest_dir",
        help="Destination directory for generated files",
    )
    parser.add_argument(
        "--axis-transform",
        dest="axis_transform",
        action="store_true",
        default=True,
        help="Convert from Z-up to Y-up (default)",
    )
    parser.add_argument(
        "--no-axis-transform",
        dest="axis_transform",
        action="store_false",
        help="Disable Z-up to Y-up conversion",
    )
    parser.add_argument(
        "--scene-units-per-meter",
        dest="scene_units_per_meter",
        type=float,
        default=None,
        help="Conversion factor from meters to Qt Quick 3D units (default: 100.0).",
    )
    parser.add_argument(
        "--instance-scale",
        dest="instance_scale",
        type=float,
        default=1.0,
        help="Extra display scale applied at the generated robot root (default: 1.0).",
    )
    parser.add_argument(
        "--scale",
        dest="scale",
        type=float,
        default=None,
        help="Deprecated alias for --scene-units-per-meter.",
    )
    parser.add_argument(
        "--mesh-unit",
        dest="mesh_unit",
        choices=["auto", "meter", "centimeter", "millimeter", "custom"],
        default="auto",
        help=(
            "Mesh source unit policy. auto: glTF/glb=meter, COLLADA uses <asset><unit>, "
            "others fallback to --mesh-default-unit."
        ),
    )
    parser.add_argument(
        "--mesh-unit-custom-to-meter",
        dest="mesh_unit_custom_to_meter",
        type=float,
        default=1.0,
        help="Meters per mesh unit when --mesh-unit=custom.",
    )
    parser.add_argument(
        "--mesh-default-unit",
        dest="mesh_default_unit",
        choices=["meter", "centimeter", "millimeter", "custom"],
        default="meter",
        help="Fallback mesh unit when --mesh-unit=auto detection fails.",
    )
    parser.add_argument(
        "--mesh-default-custom-to-meter",
        dest="mesh_default_custom_to_meter",
        type=float,
        default=1.0,
        help="Meters per mesh unit when --mesh-default-unit=custom.",
    )
    parser.add_argument(
        "--use-joints-json",
        dest="use_joints_json",
        action="store_true",
        help="Load joint information from the generated JSON file at runtime",
    )
    parser.add_argument(
        "--mesh-rotation",
        dest="mesh_rotation",
        nargs=3,
        type=float,
        metavar=("ROLL_DEG", "PITCH_DEG", "YAW_DEG"),
        default=(0.0, 0.0, 0.0),
        help="Extra rotation in degrees applied to all mesh visuals (roll pitch yaw).",
    )
    parser.add_argument(
        "--xacro-arg",
        dest="xacro_args",
        action="append",
        type=_xacro_arg,
        default=[],
        help="Pass NAME:=VALUE arguments to xacro (repeatable).",
    )
    parser.add_argument(
        "--generate-assets",
        dest="generate_assets",
        action="store_true",
        help="Generate mesh assets into Generated/QtQuick3D using Balsam importer.",
    )
    parser.add_argument(
        "--balsam-bin",
        dest="balsam_bin",
        default="balsam",
        help="Path to Balsam executable (default: balsam from PATH).",
    )
    parser.add_argument(
        "--balsam-option",
        dest="balsam_options",
        action="append",
        default=[],
        help="Extra option passed to Balsam importer (repeatable).",
    )
    parser.add_argument(
        "--balsam-timeout",
        dest="balsam_timeout",
        type=int,
        default=300,
        help="Timeout in seconds for each Balsam import invocation.",
    )
    parser.add_argument(
        "--package-map",
        dest="package_maps",
        action="append",
        type=_name_value_arg,
        default=[],
        help="Map package name to local path for package:// URI resolution (NAME:=PATH).",
    )
    parser.add_argument(
        "--license-source",
        dest="license_source",
        default=default_license_source,
        help=(
            "Path to a license file or directory to copy into generated outputs. "
            "Defaults to repository LICENSE when present."
        ),
    )
    parser.add_argument(
        "--manifest-out",
        dest="manifest_out",
        help="Write an importer-friendly JSON manifest to this path.",
    )
    parser.add_argument(
        "--ros-bridge",
        dest="ros_bridge",
        action="store_true",
        default=False,
        help=(
            "Generate ROS-bridge-aware preview files (RosPreviewScene.qml, RosMain.qml). "
            "The generated scene subscribes to /joint_states and drives the robot live. "
            "Requires QtRos2Core and QtRos2SensorMessages at build/runtime."
        ),
    )
    parser.add_argument(
        "--joint-states-topic",
        dest="joint_states_topic",
        default="/joint_states",
        help="ROS2 topic to subscribe to for joint states when --ros-bridge is used (default: /joint_states).",
    )
    parser.add_argument(
        "--physics",
        dest="physics",
        action="store_true",
        default=False,
        help=(
            "Integrate QtQuick3DPhysics rigid bodies into the robot model. "
            "Each link is wrapped in a DynamicRigidBody (or StaticRigidBody for "
            "the root), with collision shapes generated from URDF <collision> "
            "primitive geometry. Mesh collision geometry is skipped and must be "
            "added manually. Requires Qt6::Quick3DPhysics at build/runtime."
        ),
    )
    return parser


def _empty_manifest(invocation: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "status": "error",
        "robot_name": None,
        "base_name": None,
        "robot_dir": None,
        "files": {
            "robot_qml": None,
            "preview_scene_qml": None,
            "main_qml": None,
            "control_qml": None,
            "joints_json": None,
            "ros_preview_scene_qml": None,
            "ros_main_qml": None,
        },
        "generated_modules": [],
        "warnings": [],
        "error": None,
        "invocation": invocation,
    }


def _manifest_invocation(args: argparse.Namespace) -> Dict[str, Any]:
    return {
        "urdf": os.path.abspath(args.urdf),
        "dest_dir": os.path.abspath(args.dest_dir),
        "axis_transform": bool(args.axis_transform),
        "scene_units_per_meter": (
            float(args.scene_units_per_meter) if args.scene_units_per_meter is not None else None
        ),
        "instance_scale": float(args.instance_scale),
        "scale": float(args.scale) if args.scale is not None else None,
        "mesh_unit": args.mesh_unit,
        "mesh_unit_custom_to_meter": float(args.mesh_unit_custom_to_meter),
        "mesh_default_unit": args.mesh_default_unit,
        "mesh_default_custom_to_meter": float(args.mesh_default_custom_to_meter),
        "use_joints_json": bool(args.use_joints_json),
        "mesh_rotation_deg": [float(v) for v in args.mesh_rotation],
        "xacro_args": list(args.xacro_args or []),
        "generate_assets": bool(args.generate_assets),
        "balsam_bin": args.balsam_bin,
        "balsam_options": [str(v) for v in (args.balsam_options or [])],
        "balsam_timeout": int(args.balsam_timeout),
        "package_map": {},
        "raw_package_map": list(args.package_maps or []),
        "license_source": os.path.abspath(args.license_source) if args.license_source else None,
        "ros_bridge": bool(args.ros_bridge),
        "joint_states_topic": args.joint_states_topic,
        "physics": bool(args.physics),
    }


def _resolve_scene_units_per_meter(args: argparse.Namespace, warnings: List[str]) -> float:
    scene_units_per_meter = args.scene_units_per_meter
    if args.scale is not None:
        if (
            scene_units_per_meter is not None
            and not math.isclose(scene_units_per_meter, args.scale, rel_tol=0.0, abs_tol=1e-12)
        ):
            raise RuntimeError(
                "--scale and --scene-units-per-meter were both provided with different values"
            )
        scene_units_per_meter = args.scale
        warning = (
            "[urdf2quick3d] Warning: --scale is deprecated; "
            "use --scene-units-per-meter instead."
        )
        warnings.append(warning)
        print(warning)

    if scene_units_per_meter is None:
        scene_units_per_meter = 100.0
    if scene_units_per_meter <= 0.0:
        raise RuntimeError("--scene-units-per-meter must be positive")
    return float(scene_units_per_meter)


def _validate_unit_args(args: argparse.Namespace) -> None:
    if args.instance_scale <= 0.0:
        raise RuntimeError("--instance-scale must be positive")
    if args.mesh_unit_custom_to_meter <= 0.0:
        raise RuntimeError("--mesh-unit-custom-to-meter must be positive")
    if args.mesh_default_custom_to_meter <= 0.0:
        raise RuntimeError("--mesh-default-custom-to-meter must be positive")


def _write_manifest(manifest_out: str, payload: Dict[str, Any]) -> None:
    manifest_path = os.path.abspath(manifest_out)
    parent_dir = os.path.dirname(manifest_path)
    if parent_dir:
        os.makedirs(parent_dir, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def main(argv: Optional[List[str]] = None) -> int:
    parser = _create_argument_parser()
    args = parser.parse_args(argv)

    manifest = _empty_manifest(_manifest_invocation(args))
    warnings: List[str] = manifest["warnings"]
    generated_modules: List[str] = manifest["generated_modules"]
    mesh_rotation = [math.radians(v) for v in args.mesh_rotation]

    try:
        if not os.path.isdir(args.dest_dir):
            raise RuntimeError(f"Destination directory '{args.dest_dir}' does not exist")
        if args.balsam_timeout <= 0:
            raise RuntimeError("--balsam-timeout must be a positive integer")
        if args.license_source and not os.path.exists(args.license_source):
            raise RuntimeError(f"License source '{args.license_source}' does not exist")
        _validate_unit_args(args)
        scene_units_per_meter = _resolve_scene_units_per_meter(args, warnings)
        instance_scale = float(args.instance_scale)

        package_map = normalize_package_map(args.package_maps)
        manifest["invocation"]["package_map"] = dict(package_map)
        manifest["invocation"]["scene_units_per_meter"] = scene_units_per_meter
        manifest["invocation"]["scale"] = scene_units_per_meter
        manifest["invocation"]["instance_scale"] = instance_scale

        model = parse_urdf(args.urdf, xacro_args=args.xacro_args, package_map=package_map)
        unit_warning_start = len(warnings)
        apply_mesh_unit_policy(
            model,
            urdf_path=args.urdf,
            package_map=package_map,
            mesh_unit=args.mesh_unit,
            mesh_unit_custom_to_meter=args.mesh_unit_custom_to_meter,
            mesh_default_unit=args.mesh_default_unit,
            mesh_default_custom_to_meter=args.mesh_default_custom_to_meter,
            warnings=warnings,
        )
        for warning in warnings[unit_warning_start:]:
            print(warning)

        robot_dir = os.path.join(args.dest_dir, model.name)
        os.makedirs(robot_dir, exist_ok=True)
        base_name = to_pascal_case(model.name)
        joints_name = model.name
        qml_path = os.path.join(robot_dir, f"{base_name}.qml")
        base_header_path = os.path.join(robot_dir, f"{base_name}ControlBase.h")
        base_source_path = os.path.join(robot_dir, f"{base_name}ControlBase.cpp")
        control_header_path = os.path.join(robot_dir, f"{base_name}Control.h")
        control_source_path = os.path.join(robot_dir, f"{base_name}Control.cpp")
        control_qml_path = os.path.join(robot_dir, f"{base_name}Control.qml")
        joints_path = os.path.join(robot_dir, f"{joints_name}_joints.json")
        preview_scene_path = os.path.join(robot_dir, "PreviewScene.qml")
        main_qml_path = os.path.join(robot_dir, "Main.qml")
        robot_cmake_path = os.path.join(robot_dir, "CMakeLists.txt")

        manifest["robot_name"] = model.name
        manifest["base_name"] = base_name
        manifest["robot_dir"] = os.path.abspath(robot_dir)
        manifest["files"] = {
            "robot_qml": os.path.abspath(qml_path),
            "preview_scene_qml": os.path.abspath(preview_scene_path),
            "main_qml": os.path.abspath(main_qml_path),
            "control_qml": os.path.abspath(control_qml_path),
            "joints_json": os.path.abspath(joints_path),
            "ros_preview_scene_qml": None,
            "ros_main_qml": None,
        }

        license_hint = None
        if args.license_source:
            license_src = os.path.abspath(args.license_source)
            if os.path.isfile(license_src):
                license_hint = os.path.basename(license_src)
            else:
                license_hint = "LicensingFiles/"

        header_comment = (
            f"Generated by urdf2quick3dexporter.py from '{args.urdf}' on "
            f"{datetime.now().isoformat()}"
        )
        if license_hint:
            header_comment += f" | License: see {license_hint}"

        if args.license_source:
            copy_license_source_to_output(args.license_source, robot_dir)
            print(
                f"[urdf2quick3d] Copied license source '{args.license_source}' into '{robot_dir}'"
            )

        has_mesh_visuals = _mesh_visuals_exist(model)
        if args.generate_assets:
            generated_modules.extend(
                generate_mesh_assets_with_balsam(
                    model,
                    urdf_path=args.urdf,
                    robot_dir=robot_dir,
                    package_map=package_map,
                    balsam_bin=args.balsam_bin,
                    balsam_options=args.balsam_options,
                    balsam_timeout=args.balsam_timeout,
                )
            )
            print(
                "[urdf2quick3d] Generated QtQuick3D asset modules: "
                + (", ".join(generated_modules) if generated_modules else "(none)")
            )
        elif has_mesh_visuals:
            warning = (
                "[urdf2quick3d] Warning: model contains mesh visuals but --generate-assets "
                "is not enabled; Generated assets must be prepared manually."
            )
            warnings.append(warning)
            print(warning)

        write_qml(
            model,
            qml_path,
            axis_transform=args.axis_transform,
            scene_units_per_meter=scene_units_per_meter,
            instance_scale=instance_scale,
            mesh_rotation=mesh_rotation,
            header_comment=header_comment,
            physics=args.physics,
        )
        write_control_files(
            model,
            base_header_path,
            base_source_path,
            control_header_path,
            control_source_path,
            load_from_json=args.use_joints_json,
            header_comment=header_comment,
        )
        write_joint_metadata(model, joints_path)
        component_plugins = collect_component_plugins(model)
        write_robot_cmake_file(
            robot_cmake_path,
            base_name,
            component_plugins,
            joints_name,
            ros_bridge=args.ros_bridge,
            physics=args.physics,
            header_comment=header_comment,
        )
        write_qmldir(base_name, os.path.join(robot_dir, "qmldir"), header_comment=header_comment)
        write_control_qml(
            model,
            robot_dir,
            load_from_json=args.use_joints_json,
            header_comment=header_comment,
        )
        write_control_panel_qml(base_name, robot_dir, header_comment=header_comment)
        write_preview_scene_qml(base_name, robot_dir, physics=args.physics, header_comment=header_comment)
        write_preview_qml(base_name, robot_dir, header_comment=header_comment)
        write_main_cpp(base_name, robot_dir, header_comment=header_comment)
        write_qmlproject(base_name, robot_dir, header_comment=header_comment)

        if args.ros_bridge:
            ros_preview_scene_path = os.path.join(robot_dir, "RosPreviewScene.qml")
            ros_main_qml_path = os.path.join(robot_dir, "RosMain.qml")
            write_ros_preview_scene_qml(
                base_name,
                model,
                robot_dir,
                joint_states_topic=args.joint_states_topic,
                header_comment=header_comment,
            )
            write_ros_main_qml(base_name, robot_dir, header_comment=header_comment)
            manifest["files"]["ros_preview_scene_qml"] = os.path.abspath(ros_preview_scene_path)
            manifest["files"]["ros_main_qml"] = os.path.abspath(ros_main_qml_path)

        # Physics bodies are integrated into the robot model QML directly.

        generated_dir = os.path.join(robot_dir, "Generated")
        if args.license_source and os.path.isdir(generated_dir):
            copy_license_source_to_output(args.license_source, generated_dir)
            print(
                f"[urdf2quick3d] Copied license source '{args.license_source}' into '{generated_dir}'"
            )

        manifest["status"] = "ok"
        manifest["error"] = None

        if args.manifest_out:
            _write_manifest(args.manifest_out, manifest)

        print(
            f"Written {qml_path}, {base_header_path}, {base_source_path}, {joints_path}, "
            f"{robot_cmake_path} and preview files"
        )
        return 0
    except Exception as exc:
        manifest["status"] = "error"
        manifest["error"] = str(exc)
        if args.manifest_out:
            try:
                _write_manifest(args.manifest_out, manifest)
            except Exception as manifest_exc:
                print(f"[urdf2quick3d] Error: {exc}", file=sys.stderr)
                print(
                    f"[urdf2quick3d] Error: failed to write manifest '{args.manifest_out}': "
                    f"{manifest_exc}",
                    file=sys.stderr,
                )
                return 1
            print(f"[urdf2quick3d] Error: {exc}", file=sys.stderr)
            return 1
        parser.error(str(exc))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
