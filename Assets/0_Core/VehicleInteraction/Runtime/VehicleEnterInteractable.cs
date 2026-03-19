using NWH.Common.SceneManagement;
using NWH.Common.Input;
using NWH.Common.Vehicles;
using NWH.VehiclePhysics2.Input;
using PolymindGames;
using UnityEngine;
using System.Collections;

namespace BtlGame.VehicleInteraction
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Interactable))]
    public sealed class VehicleEnterInteractable : MonoBehaviour
    {
        [SerializeField]
        [Tooltip("Vehicle that should be entered when this interactable is used.")]
        private Vehicle _vehicle;

        [SerializeField]
        [Tooltip("VehicleChanger used to enter the vehicle.")]
        private VehicleChanger _vehicleChanger;

        [SerializeField]
        [Tooltip("If enabled, assigns VehicleChanger.characterObject from the interacting character.")]
        private bool _assignCharacterObjectFromInteractor = true;

        [SerializeField]
        [Tooltip("If true, ignores vehicle speed check when entering.")]
        private bool _ignoreEnterSpeedLimit = true;

        [SerializeField]
        [Tooltip("If true, first triggers NWH ChangeVehicle input flow and only falls back to direct enter.")]
        private bool _preferNwhInputFlow = false;

        [SerializeField]
        [Tooltip("Optional transition manager for black fade + UI fade sequencing.")]
        private VehicleUiTransitionManager _transitionManager;

        [SerializeField]
        [Tooltip("Maximum flat distance from the player at which this vehicle can be hovered/interacted.")]
        private float _interactionDistance = 3f;

        [SerializeField]
        [Tooltip("If true, creates a VehicleChanger automatically if missing in scene.")]
        private bool _autoCreateVehicleChanger = true;

        [Header("Prompt Defaults")]
        [SerializeField]
        private string _defaultTitle = "Vehicle";

        [SerializeField]
        private string _defaultDescription = "Press F to enter";

        private Interactable _interactable;
        private Transform _playerTransform;
        private Transform[] _enterExitPoints;

        private void Awake()
        {
            _interactable = GetComponent<Interactable>();
            ResolveReferences();
            ApplyPromptDefaults();
            CacheEnterExitPoints();
        }

        private void LateUpdate()
        {
            if (_interactable == null)
                return;

            if (_interactionDistance <= 0.01f)
            {
                _interactable.enabled = true;
                return;
            }

            if (_playerTransform == null)
                ResolvePlayerTransform();

            if (_playerTransform == null)
            {
                _interactable.enabled = true;
                return;
            }

            Vector3 nearestPoint = GetNearestEnterExitPosition(_playerTransform.position);
            Vector3 delta = nearestPoint - _playerTransform.position;
            delta.y = 0f;
            _interactable.enabled = delta.sqrMagnitude <= _interactionDistance * _interactionDistance;
        }

        private void OnEnable()
        {
            if (_interactable == null)
                _interactable = GetComponent<Interactable>();

            _interactable.Interacted += OnInteracted;
        }

        private void OnDisable()
        {
            if (_interactable != null)
                _interactable.Interacted -= OnInteracted;
        }

        private void OnInteracted(IInteractable interactable, ICharacter character)
        {
            ResolveReferences();

            if (_vehicle == null || _vehicleChanger == null)
            {
                Debug.LogWarning($"{nameof(VehicleEnterInteractable)} on '{name}' is missing references.", this);
                return;
            }

            if (_assignCharacterObjectFromInteractor)
            {
                GameObject characterObject = ResolveCharacterObject(character);
                if (characterObject != null && _vehicleChanger.characterObject != characterObject)
                {
                    _vehicleChanger.characterObject = characterObject;
                    _playerTransform = characterObject.transform;
                }
            }

            if (!_ignoreEnterSpeedLimit && _vehicle.Speed >= _vehicleChanger.maxEnterExitVehicleSpeed)
                return;

            _vehicleChanger.characterBased = _vehicleChanger.characterObject != null;

            VehicleExitInteractInput exitInput = _vehicleChanger.GetComponent<VehicleExitInteractInput>();
            exitInput?.BlockExitForDuration();

            if (_vehicleChanger.characterBased)
            {
                if (_transitionManager != null)
                {
                    _transitionManager.PlayTransitionToVehicleState(true, EnterVehicleNow);
                }
                else if (_preferNwhInputFlow)
                {
                    InteractSceneInputProvider.RequestChangeVehicle();
                    StartCoroutine(EnterFallbackNextFrame(_vehicleChanger, _vehicle));
                }
                else
                {
                    EnterVehicleNow();
                }
            }
            else
            {
                if (_transitionManager != null)
                    _transitionManager.PlayTransitionToVehicleState(true, EnterVehicleNow);
                else
                    EnterVehicleNow();
            }
        }

        private IEnumerator EnterFallbackNextFrame(VehicleChanger changer, Vehicle vehicle)
        {
            yield return null;

            if (changer == null || vehicle == null)
                yield break;

            if (changer.location == VehicleChanger.CharacterLocation.Inside)
                yield break;

            if (!_ignoreEnterSpeedLimit && vehicle.Speed >= changer.maxEnterExitVehicleSpeed)
                yield break;

            changer.EnterVehicle(vehicle);
        }

        private static GameObject ResolveCharacterObject(ICharacter character)
        {
            if (character is not Component characterComponent)
                return null;

            return characterComponent.gameObject;
        }

        private void ResolveReferences()
        {
            if (_vehicle == null)
                _vehicle = GetComponentInParent<Vehicle>();

            if (_vehicleChanger == null)
                _vehicleChanger = VehicleChanger.Instance != null
                    ? VehicleChanger.Instance
                    : FindFirstObjectByType<VehicleChanger>();

            if (_vehicleChanger == null && _autoCreateVehicleChanger)
            {
                GameObject changerGO = new GameObject("VehicleChanger_Auto");
                _vehicleChanger = changerGO.AddComponent<VehicleChanger>();
                _vehicleChanger.characterBased = true;
            }

            if (_vehicleChanger != null)
            {
                if (_transitionManager == null)
                {
                    _transitionManager = _vehicleChanger.GetComponent<VehicleUiTransitionManager>();
                    if (_transitionManager == null)
                        _transitionManager = FindFirstObjectByType<VehicleUiTransitionManager>();
                }

                if (_vehicle != null && !_vehicleChanger.vehicles.Contains(_vehicle))
                    _vehicleChanger.RegisterVehicle(_vehicle);

                EnsureVehicleInputProvider();
                EnsureSceneInputProvider();
                EnsureVehicleOrbitCamera();

                if (_vehicleChanger.characterObject == null)
                {
                    ResolvePlayerTransform();
                    if (_playerTransform != null)
                        _vehicleChanger.characterObject = _playerTransform.gameObject;
                }

                if (_vehicleChanger.GetComponent<VehicleExitInteractInput>() == null)
                    _vehicleChanger.gameObject.AddComponent<VehicleExitInteractInput>();
            }
        }

        private void EnterVehicleNow()
        {
            if (_vehicleChanger == null || _vehicle == null)
                return;

            if (_vehicleChanger.characterBased)
                _vehicleChanger.EnterVehicle(_vehicle);
            else
                _vehicleChanger.ChangeVehicle(_vehicle);
        }

        private void EnsureVehicleOrbitCamera()
        {
            if (_vehicle == null)
                return;

            Camera[] cameras = _vehicle.GetComponentsInChildren<Camera>(true);
            for (int i = 0; i < cameras.Length; i++)
            {
                Camera cam = cameras[i];
                if (cam == null)
                    continue;

                if (!ShouldReplaceWithOrbit(cam.gameObject))
                    continue;

                VehicleOrbitCamera orbit = cam.GetComponent<VehicleOrbitCamera>();
                if (orbit == null)
                    orbit = cam.gameObject.AddComponent<VehicleOrbitCamera>();

                orbit.SetTarget(_vehicle.transform);
            }
        }

        private static bool ShouldReplaceWithOrbit(GameObject cameraObject)
        {
            if (cameraObject == null)
                return false;

            if (cameraObject.name.Contains("Cinemachine"))
                return true;

            MonoBehaviour[] behaviours = cameraObject.GetComponents<MonoBehaviour>();
            for (int i = 0; i < behaviours.Length; i++)
            {
                MonoBehaviour behaviour = behaviours[i];
                if (behaviour == null)
                    continue;

                string ns = behaviour.GetType().Namespace;
                if (!string.IsNullOrEmpty(ns) && ns.StartsWith("Cinemachine"))
                    return true;
            }

            return false;
        }

        private void EnsureSceneInputProvider()
        {
            if (_vehicleChanger == null)
                return;

            if (FindFirstObjectByType<SceneInputProviderBase>() != null)
                return;

            _vehicleChanger.gameObject.AddComponent<InteractSceneInputProvider>();
        }

        private void EnsureVehicleInputProvider()
        {
            if (_vehicleChanger == null)
                return;

            if (FindFirstObjectByType<VehicleInputProviderBase>() != null)
                return;

            _vehicleChanger.gameObject.AddComponent<InputSystemVehicleInputProvider>();
        }

        private void ResolvePlayerTransform()
        {
            if (_playerTransform != null)
                return;

            if (_vehicleChanger != null && _vehicleChanger.characterObject != null)
            {
                _playerTransform = _vehicleChanger.characterObject.transform;
                return;
            }

            HumanCharacter humanCharacter = FindFirstObjectByType<HumanCharacter>();
            if (humanCharacter != null)
            {
                _playerTransform = humanCharacter.transform;
                return;
            }

            GameObject player = GameObject.FindGameObjectWithTag(TagConstants.Player);
            if (player != null)
                _playerTransform = player.transform;
        }

        private void CacheEnterExitPoints()
        {
            if (_vehicle == null)
                return;

            _enterExitPoints = _vehicle.GetComponentsInChildren<Transform>(true);
        }

        private Vector3 GetNearestEnterExitPosition(Vector3 fromPosition)
        {
            if (_vehicle == null)
                return transform.position;

            if (_enterExitPoints == null || _enterExitPoints.Length == 0)
                CacheEnterExitPoints();

            Vector3 nearest = _vehicle.transform.position;
            float bestSqr = float.MaxValue;

            if (_enterExitPoints != null)
            {
                for (int i = 0; i < _enterExitPoints.Length; i++)
                {
                    Transform t = _enterExitPoints[i];
                    if (t == null || !t.CompareTag(_vehicleChanger != null ? _vehicleChanger.enterExitTag : "EnterExitPoint"))
                        continue;

                    Vector3 delta = t.position - fromPosition;
                    delta.y = 0f;
                    float sqr = delta.sqrMagnitude;
                    if (sqr < bestSqr)
                    {
                        bestSqr = sqr;
                        nearest = t.position;
                    }
                }
            }

            return nearest;
        }

        private void ApplyPromptDefaults()
        {
            if (_interactable == null)
                return;

            if (string.IsNullOrWhiteSpace(_interactable.Title))
                _interactable.Title = _defaultTitle;

            if (string.IsNullOrWhiteSpace(_interactable.Description))
                _interactable.Description = _defaultDescription;
        }

#if UNITY_EDITOR
        private void Reset()
        {
            _interactable = GetComponent<Interactable>();
            ResolveReferences();
            ApplyPromptDefaults();
        }

        private void OnValidate()
        {
            ResolveReferences();
            CacheEnterExitPoints();
        }
#endif
    }
}
