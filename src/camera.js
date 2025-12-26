const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

class Vector3 {
  constructor(x = 0, y = 0, z = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  clone() {
    return new Vector3(this.x, this.y, this.z);
  }

  subtract(other) {
    return new Vector3(this.x - other.x, this.y - other.y, this.z - other.z);
  }

  length() {
    return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
  }

  normalize() {
    const len = this.length();
    if (len === 0) return new Vector3(0, 0, 0);
    return new Vector3(this.x / len, this.y / len, this.z / len);
  }
}

class CameraRig {
  constructor(position = new Vector3(), target = new Vector3(0, 0, 0)) {
    this.position = position;
    this.target = target;
    this.forward = new Vector3(0, 0, -1);
  }

  lookAt(target) {
    this.target = target.clone();
    this.forward = target.subtract(this.position).normalize();
  }
}

class CameraController {
  constructor({
    yaw = 0,
    pitch = 0,
    radius = 10,
    minRadius = 2,
    maxRadius = 40,
    pitchEpsilon = 0.001,
    boardRoot = new Vector3(0, 0, 0),
    rig = new CameraRig(),
    yawSensitivity = 1,
    pitchSensitivity = 1,
  } = {}) {
    this.yaw = yaw;
    this.pitch = pitch;
    this.radius = radius;
    this.minRadius = minRadius;
    this.maxRadius = maxRadius;
    this.pitchEpsilon = pitchEpsilon;
    this.boardRoot = boardRoot;
    this.rig = rig;
    this.yawSensitivity = yawSensitivity;
    this.pitchSensitivity = pitchSensitivity;
    this.updateRig();
  }

  updateRig() {
    const cosPitch = Math.cos(this.pitch);
    const sinPitch = Math.sin(this.pitch);
    const sinYaw = Math.sin(this.yaw);
    const cosYaw = Math.cos(this.yaw);

    const x = this.boardRoot.x + this.radius * cosPitch * sinYaw;
    const y = this.boardRoot.y + this.radius * sinPitch;
    const z = this.boardRoot.z + this.radius * cosPitch * cosYaw;

    this.rig.position = new Vector3(x, y, z);
    this.rig.lookAt(this.boardRoot);
    return this.rig;
  }

  onDrag(deltaX, deltaY) {
    this.yaw += deltaX * this.yawSensitivity;
    this.pitch += deltaY * this.pitchSensitivity;

    const limit = Math.PI / 2 - this.pitchEpsilon;
    this.pitch = clamp(this.pitch, -limit, limit);
    return this.updateRig();
  }

  onPinch(deltaRadius) {
    this.radius = clamp(this.radius + deltaRadius, this.minRadius, this.maxRadius);
    return this.updateRig();
  }

  setBoardRoot(boardRoot) {
    this.boardRoot = boardRoot;
    return this.updateRig();
  }
}

module.exports = {
  clamp,
  Vector3,
  CameraRig,
  CameraController,
};
