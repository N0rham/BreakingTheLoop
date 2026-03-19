using System.Collections.Generic;
using Enviro;
using NWH.Common.SceneManagement;
using NWH.Common.Vehicles;
using NWH.VehiclePhysics2;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering.Universal;

namespace BtlGame.VehicleInteraction
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Camera))]
    public sealed class VehicleOrbitCamera : MonoBehaviour
    {
        [Header("Target")]
        [SerializeField]
        private Transform _target;

        [SerializeField]
        private Vector3 _targetOffset = new(0f, 1.2f, 0f);

        [Header("Distance")]
        [SerializeField]
        private float _distance = 6f;

        [SerializeField]
        private float _minDistance = 3f;

        [SerializeField]
        private float _maxDistance = 10f;

        [SerializeField]
        private float _zoomSpeed = 4f;

        [SerializeField]
        private float _zoomSmoothing = 18f;

        [Header("Orbit")]
        [SerializeField]
        private float _yawSensitivity = 0.12f;

        [SerializeField]
        private float _pitchSensitivity = 0.1f;

        [SerializeField]
        private float _maxMouseDeltaPerFrame = 40f;

        [SerializeField]
        private float _minPitch = -12f;

        [SerializeField]
        private float _maxPitch = 65f;

        [SerializeField]
        private bool _requireRightMouseButton;

        [SerializeField]
        private float _manualInputDeadzone = 0.001f;

        [Header("Recenter")]
        [SerializeField]
        private float _recenterDelay = 0.8f;

        [SerializeField]
        private float _recenterSpeed = 4f;

        [SerializeField]
        private float _reverseLocalSpeedThreshold = -0.5f;

        [Header("Smoothing")]
        [SerializeField]
        private float _focusSmoothing = 20f;

        [SerializeField]
        private float _orbitSmoothing = 18f;

        [Header("Collision")]
        [SerializeField]
        private LayerMask _collisionMask = ~0;

        [SerializeField]
        private float _collisionRadius = 0.25f;

        [SerializeField]
        private float _collisionPadding = 0.2f;

        [SerializeField]
        private bool _ignoreTargetColliders = true;

        [Header("Tag Handoff")]
        [SerializeField]
        private bool _switchCameraTags = true;

        [SerializeField]
        private string _activeCameraTag = "MainCamera";

        [SerializeField]
        private string _inactiveCameraTag = "VehicleCam";

        private Rigidbody _targetRigidbody;
        private Vehicle _targetVehicle;
        private float _yaw;
        private float _pitch = 12f;
        private float _yawTarget;
        private float _pitchTarget = 12f;
        private float _yawVelocity;
        private float _pitchVelocity;
        private float _lastManualInputTime;
        private bool _initializedAngles;
        private Collider[] _targetColliders;
        private Vector3 _focusPoint;
        private float _distanceCurrent;
        private float _distanceTarget;
        private bool _wasReversing;
        private Camera _camera;
        private AudioListener _audioListener;
        private VehicleChanger _vehicleChanger;
        private bool _cameraWasActive;
        private readonly List<AudioListener> _suppressedListeners = new();
        private bool _hasStoredOriginalTag;
        private string _originalTag;
        private VehicleController _targetVehicleController;

        public void SetTarget(Transform target)
        {
            _target = target;
            if (_target != null)
            {
                _targetRigidbody = _target.GetComponent<Rigidbody>();
                _targetVehicle = _target.GetComponent<Vehicle>();
                _targetVehicleController = _target.GetComponent<VehicleController>();
                _targetColliders = _target.GetComponentsInChildren<Collider>(true);
            }
            else
            {
                _targetRigidbody = null;
                _targetVehicle = null;
                _targetVehicleController = null;
                _targetColliders = null;
            }

            _initializedAngles = false;
        }

        private void Awake()
        {
            _camera = GetComponent<Camera>();
            _audioListener = GetComponent<AudioListener>();
            _camera.enabled = false;
            if (_audioListener != null)
                _audioListener.enabled = false;
            EnsureURPPostProcessing();
            DisableCinemachineComponentsOnThisObject();
            ResolveTargetIfNeeded();
            ResolveVehicleChangerIfNeeded();
        }

        private void EnsureURPPostProcessing()
        {
            var urpData = GetComponent<UniversalAdditionalCameraData>();
            if (urpData == null)
                urpData = gameObject.AddComponent<UniversalAdditionalCameraData>();
            urpData.renderPostProcessing = true;
            urpData.antialiasing = AntialiasingMode.TemporalAntiAliasing;
            urpData.antialiasingQuality = AntialiasingQuality.High;
        }

        private void OnEnable()
        {
            DisableCinemachineComponentsOnThisObject();
            ResolveTargetIfNeeded();
            ResolveVehicleChangerIfNeeded();
        }

        private void LateUpdate()
        {
            if (!ResolveTargetIfNeeded())
                return;

            ResolveVehicleChangerIfNeeded();
            bool isActiveVehicle = IsPlayerInThisVehicle();

            if (isActiveVehicle && !_cameraWasActive)
                _initializedAngles = false;

            _cameraWasActive = isActiveVehicle;
            _camera.enabled = isActiveVehicle;
            UpdateExclusiveAudioListener(isActiveVehicle);
            UpdateCameraRole(isActiveVehicle);

            if (!isActiveVehicle)
                return;

            InitializeAnglesIfNeeded();

            float dt = Time.deltaTime;
            Vector2 lookDelta = ReadLookInput();
            bool hasManualInput = lookDelta.sqrMagnitude > _manualInputDeadzone;
            bool isReversing = IsReversing();
            bool reverseStateChanged = isReversing != _wasReversing;
            _wasReversing = isReversing;

            if (hasManualInput)
            {
                _yawTarget += lookDelta.x * _yawSensitivity;
                _pitchTarget -= lookDelta.y * _pitchSensitivity;
                _pitchTarget = Mathf.Clamp(_pitchTarget, _minPitch, _maxPitch);
                _lastManualInputTime = Time.unscaledTime;
            }
            else if (reverseStateChanged || Time.unscaledTime - _lastManualInputTime > _recenterDelay)
            {
                float desiredYaw = _target.eulerAngles.y + (isReversing ? 180f : 0f);
                _yawTarget = Mathf.LerpAngle(_yawTarget, desiredYaw, 1f - Mathf.Exp(-_recenterSpeed * dt));
            }

            float orbitSmoothTime = 1f / Mathf.Max(0.01f, _orbitSmoothing);
            _yaw = Mathf.SmoothDampAngle(_yaw, _yawTarget, ref _yawVelocity, orbitSmoothTime, Mathf.Infinity, dt);
            _pitch = Mathf.SmoothDampAngle(_pitch, _pitchTarget, ref _pitchVelocity, orbitSmoothTime, Mathf.Infinity, dt);
            _pitch = Mathf.Clamp(_pitch, _minPitch, _maxPitch);

            float scrollInput = ReadScrollInput();
            if (Mathf.Abs(scrollInput) > 0.0001f)
                _distanceTarget = Mathf.Clamp(_distanceTarget - scrollInput * _zoomSpeed * dt, _minDistance, _maxDistance);

            Vector3 rawFocusPoint = _target.position + _target.TransformDirection(_targetOffset);
            float focusLerp = 1f - Mathf.Exp(-_focusSmoothing * dt);
            _focusPoint = Vector3.Lerp(_focusPoint, rawFocusPoint, focusLerp);

            float zoomLerp = 1f - Mathf.Exp(-_zoomSmoothing * dt);
            _distanceCurrent = Mathf.Lerp(_distanceCurrent, _distanceTarget, zoomLerp);

            Quaternion orbitRotation = Quaternion.Euler(_pitch, _yaw, 0f);
            Vector3 desiredPosition = _focusPoint - orbitRotation * Vector3.forward * _distanceCurrent;
            Vector3 finalPosition = ResolveCollisionAdjustedPosition(_focusPoint, desiredPosition);

            Vector3 lookDirection = _focusPoint - finalPosition;
            if (lookDirection.sqrMagnitude > 0.0001f)
            {
                Quaternion finalRotation = Quaternion.LookRotation(lookDirection.normalized, Vector3.up);
                transform.SetPositionAndRotation(finalPosition, finalRotation);
            }
        }

        private Vector3 ResolveCollisionAdjustedPosition(Vector3 focusPoint, Vector3 desiredPosition)
        {
            Vector3 direction = desiredPosition - focusPoint;
            float distance = direction.magnitude;
            if (distance < 0.001f)
                return desiredPosition;

            direction /= distance;
            RaycastHit[] hits = Physics.SphereCastAll(
                focusPoint,
                _collisionRadius,
                direction,
                distance,
                _collisionMask,
                QueryTriggerInteraction.Ignore);

            if (hits == null || hits.Length == 0)
                return desiredPosition;

            float bestDistance = float.MaxValue;
            bool hasExternalHit = false;

            for (int i = 0; i < hits.Length; i++)
            {
                RaycastHit hit = hits[i];
                if (hit.collider == null)
                    continue;

                if (_ignoreTargetColliders && IsTargetCollider(hit.collider))
                    continue;

                if (hit.distance < bestDistance)
                {
                    bestDistance = hit.distance;
                    hasExternalHit = true;
                }
            }

            if (!hasExternalHit)
                return desiredPosition;

            float clampedDistance = Mathf.Max(0.5f, bestDistance - _collisionPadding);
            return focusPoint + direction * clampedDistance;
        }

        private bool ResolveTargetIfNeeded()
        {
            if (_target != null)
                return true;

            Vehicle vehicle = GetComponentInParent<Vehicle>();
            if (vehicle == null)
                return false;

            _target = vehicle.transform;
            _targetRigidbody = vehicle.GetComponent<Rigidbody>();
            _targetVehicle = vehicle;
            _targetVehicleController = vehicle.GetComponent<VehicleController>();
            _targetColliders = _target.GetComponentsInChildren<Collider>(true);
            return true;
        }

        private void InitializeAnglesIfNeeded()
        {
            if (_initializedAngles)
                return;

            Vector3 euler = transform.eulerAngles;
            _yaw = euler.y;
            _pitch = NormalizePitch(euler.x);
            _pitch = Mathf.Clamp(_pitch, _minPitch, _maxPitch);
            _yawTarget = _yaw;
            _pitchTarget = _pitch;
            _yawVelocity = 0f;
            _pitchVelocity = 0f;
            _focusPoint = _target.position + _target.TransformDirection(_targetOffset);
            _distanceTarget = Mathf.Clamp(_distance, _minDistance, _maxDistance);
            _distanceCurrent = _distanceTarget;
            _wasReversing = IsReversing();
            _lastManualInputTime = Time.unscaledTime;
            _initializedAngles = true;
        }

        private bool IsReversing()
        {
            if (_targetVehicle != null)
                return _targetVehicle.SpeedSigned < _reverseLocalSpeedThreshold;

            if (_targetRigidbody == null || _target == null)
                return false;

            Vector3 localVelocity = _target.InverseTransformDirection(_targetRigidbody.linearVelocity);
            return localVelocity.z < _reverseLocalSpeedThreshold;
        }

        private Vector2 ReadLookInput()
        {
            Mouse mouse = Mouse.current;
            if (mouse == null)
                return Vector2.zero;

            if (_requireRightMouseButton && !mouse.rightButton.isPressed)
                return Vector2.zero;

            Vector2 delta = mouse.delta.ReadValue();
            delta.x = Mathf.Clamp(delta.x, -_maxMouseDeltaPerFrame, _maxMouseDeltaPerFrame);
            delta.y = Mathf.Clamp(delta.y, -_maxMouseDeltaPerFrame, _maxMouseDeltaPerFrame);
            return delta;
        }

        private static float ReadScrollInput()
        {
            Mouse mouse = Mouse.current;
            if (mouse == null)
                return 0f;

            return mouse.scroll.ReadValue().y;
        }

        private void ResolveVehicleChangerIfNeeded()
        {
            if (_vehicleChanger != null)
                return;

            _vehicleChanger = VehicleChanger.Instance != null
                ? VehicleChanger.Instance
                : FindFirstObjectByType<VehicleChanger>();
        }

        private bool IsPlayerInThisVehicle()
        {
            if (_vehicleChanger == null)
                return false;

            if (_vehicleChanger.location != VehicleChanger.CharacterLocation.Inside)
                return false;

            int idx = _vehicleChanger.activeVehicleIndex;
            if (idx < 0 || idx >= _vehicleChanger.vehicles.Count)
                return false;

            Vehicle activeVehicle = _vehicleChanger.vehicles[idx];
            if (activeVehicle == null)
                return false;

            if (_targetVehicle != null)
                return activeVehicle == _targetVehicle;

            // Fallback for setups where the Vehicle component is not on the exact target transform.
            if (_target != null)
                return activeVehicle.transform == _target || _target.IsChildOf(activeVehicle.transform);

            return false;
        }

        private void DisableCinemachineComponentsOnThisObject()
        {
            MonoBehaviour[] behaviours = GetComponents<MonoBehaviour>();
            for (int i = 0; i < behaviours.Length; i++)
            {
                MonoBehaviour behaviour = behaviours[i];
                if (behaviour == null || behaviour == this)
                    continue;

                string ns = behaviour.GetType().Namespace;
                if (!string.IsNullOrEmpty(ns) && ns.StartsWith("Cinemachine"))
                    behaviour.enabled = false;
            }
        }

        private void OnDisable()
        {
            if (_camera != null)
                _camera.enabled = false;

            UpdateExclusiveAudioListener(false);
            UpdateCameraRole(false);
        }

        private void UpdateCameraRole(bool isVehicleCameraActive)
        {
            UpdateCameraTag(isVehicleCameraActive);
            UpdateVehicleLodCamera(isVehicleCameraActive);
            UpdateEnviroCamera(isVehicleCameraActive);
        }

        private void UpdateVehicleLodCamera(bool isVehicleCameraActive)
        {
            if (_targetVehicleController == null || _camera == null)
                return;

            if (isVehicleCameraActive)
            {
                _targetVehicleController.lodCamera = _camera;
            }
            else if (_targetVehicleController.lodCamera == _camera)
            {
                _targetVehicleController.lodCamera = null;
            }
        }

        private void UpdateEnviroCamera(bool isVehicleCameraActive)
        {
            if (_camera == null || EnviroManager.instance == null)
                return;

            if (isVehicleCameraActive)
            {
                EnviroManager.instance.ChangeCamera(_camera);
                EnviroManager.instance.AddAdditionalCamera(_camera);
            }
        }

        private void UpdateCameraTag(bool isVehicleCameraActive)
        {
            if (!_switchCameraTags)
                return;

            if (!TryReadCurrentTag(out string currentTag))
                return;

            if (!_hasStoredOriginalTag)
            {
                _originalTag = currentTag;
                _hasStoredOriginalTag = true;
            }

            if (isVehicleCameraActive)
            {
                TrySetTag(_activeCameraTag);
            }
            else
            {
                string targetTag = string.IsNullOrWhiteSpace(_inactiveCameraTag) ? _originalTag : _inactiveCameraTag;
                TrySetTag(targetTag);
            }
        }

        private bool TryReadCurrentTag(out string tagValue)
        {
            tagValue = string.Empty;

            try
            {
                tagValue = gameObject.tag;
                return true;
            }
            catch (UnityException)
            {
                return false;
            }
        }

        private void TrySetTag(string tagValue)
        {
            if (string.IsNullOrWhiteSpace(tagValue))
                return;

            try
            {
                if (gameObject.tag != tagValue)
                    gameObject.tag = tagValue;
            }
            catch (UnityException)
            {
                // Ignore invalid tag names. This allows optional custom tags without hard failure.
            }
        }

        private void UpdateExclusiveAudioListener(bool isVehicleCameraActive)
        {
            if (_audioListener == null)
                return;

            if (isVehicleCameraActive)
            {
                _audioListener.enabled = true;

                AudioListener[] listeners = FindObjectsByType<AudioListener>(FindObjectsSortMode.None);
                for (int i = 0; i < listeners.Length; i++)
                {
                    AudioListener listener = listeners[i];
                    if (listener == null || listener == _audioListener)
                        continue;

                    if (listener.enabled)
                    {
                        listener.enabled = false;
                        _suppressedListeners.Add(listener);
                    }
                }
            }
            else
            {
                _audioListener.enabled = false;

                for (int i = 0; i < _suppressedListeners.Count; i++)
                {
                    AudioListener listener = _suppressedListeners[i];
                    if (listener != null)
                        listener.enabled = true;
                }

                _suppressedListeners.Clear();
            }
        }

        private static float NormalizePitch(float pitch)
        {
            if (pitch > 180f)
                pitch -= 360f;

            return pitch;
        }

        private bool IsTargetCollider(Collider col)
        {
            if (col == null)
                return false;

            if (_target == null)
                return false;

            if (col.transform.IsChildOf(_target))
                return true;

            if (_targetColliders == null)
                return false;

            for (int i = 0; i < _targetColliders.Length; i++)
            {
                if (_targetColliders[i] == col)
                    return true;
            }

            return false;
        }
    }
}
