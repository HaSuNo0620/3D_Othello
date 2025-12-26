# 3D_Othello

## Camera controller

`src/camera.js` に軌道カメラ向けの `CameraController` と `CameraRig` を実装しています。`yaw / pitch / radius` を保持し、ドラッグでの方位・仰俯角更新、ピンチでの距離更新を行い、常に `BoardRoot`（ターゲット）を `lookAt` するようにしています。テストは `npm test` で実行できます。
