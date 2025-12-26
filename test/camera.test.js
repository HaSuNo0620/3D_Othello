const assert = require('assert');
const { CameraController, Vector3 } = require('../src/camera');

const almostEqual = (a, b, eps = 1e-6) => Math.abs(a - b) < eps;

const assertVecClose = (vec, expected, eps = 1e-6) => {
  assert.ok(almostEqual(vec.x, expected.x, eps), `x mismatch: ${vec.x} vs ${expected.x}`);
  assert.ok(almostEqual(vec.y, expected.y, eps), `y mismatch: ${vec.y} vs ${expected.y}`);
  assert.ok(almostEqual(vec.z, expected.z, eps), `z mismatch: ${vec.z} vs ${expected.z}`);
};

const runTests = () => {
  {
    const controller = new CameraController({ radius: 10 });
    assertVecClose(controller.rig.position, new Vector3(0, 0, 10));
    assertVecClose(controller.rig.forward, new Vector3(0, 0, -1));
  }

  {
    const controller = new CameraController({ radius: 10 });
    controller.onDrag(0.5, 0);
    const expectedX = 10 * Math.cos(0) * Math.sin(0.5);
    const expectedZ = 10 * Math.cos(0) * Math.cos(0.5);
    assertVecClose(controller.rig.position, new Vector3(expectedX, 0, expectedZ));
    assertVecClose(controller.rig.forward, controller.rig.target.subtract(controller.rig.position).normalize());
  }

  {
    const epsilon = 0.01;
    const controller = new CameraController({ pitch: Math.PI / 2 - epsilon, pitchEpsilon: epsilon });
    controller.onDrag(0, 0.5);
    const limit = Math.PI / 2 - epsilon;
    assert.ok(almostEqual(controller.pitch, limit));
  }

  {
    const controller = new CameraController({ radius: 5, minRadius: 2, maxRadius: 6 });
    controller.onPinch(-5);
    assert.strictEqual(controller.radius, 2);
    controller.onPinch(10);
    assert.strictEqual(controller.radius, 6);
  }

  {
    const controller = new CameraController({ boardRoot: new Vector3(1, 2, 3), radius: 1 });
    controller.setBoardRoot(new Vector3(-1, -2, -3));
    assertVecClose(controller.rig.target, new Vector3(-1, -2, -3));
  }
};

runTests();
console.log('All camera controller tests passed.');
