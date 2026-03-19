using NWH.Common.SceneManagement;
using NWH.Common.Vehicles;
using PolymindGames.InputSystem;
using UnityEngine;
using UnityEngine.InputSystem;

namespace BtlGame.VehicleInteraction
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(VehicleChanger))]
    public sealed class VehicleExitInteractInput : MonoBehaviour
    {
        [SerializeField]
        [Tooltip("Reference the same Interact action used by FPS interaction (F).")]
        private InputActionReference _interactAction;

        [SerializeField]
        [Tooltip("Fallback key used when no input action reference is assigned.")]
        private Key _fallbackKey = Key.F;

        [SerializeField]
        [Tooltip("Minimum delay after entering before exit input is accepted.")]
        private float _exitBlockDuration = 0.3f;

        [SerializeField]
        [Tooltip("Optional transition manager for black fade + UI fade sequencing.")]
        private VehicleUiTransitionManager _transitionManager;

        private VehicleChanger _vehicleChanger;
        private float _ignoreExitUntilTime;

        private void Awake()
        {
            _vehicleChanger = GetComponent<VehicleChanger>();
            if (_transitionManager == null)
            {
                _transitionManager = GetComponent<VehicleUiTransitionManager>();
                if (_transitionManager == null)
                    _transitionManager = FindFirstObjectByType<VehicleUiTransitionManager>();
            }
        }

        private void OnEnable()
        {
            if (_interactAction != null)
                _interactAction.RegisterStarted(OnInteractStarted);
        }

        private void OnDisable()
        {
            if (_interactAction != null)
                _interactAction.UnregisterStarted(OnInteractStarted);
        }

        private void Update()
        {
            if (_interactAction != null)
                return;

            if (Keyboard.current == null)
                return;

            if (Keyboard.current[_fallbackKey].wasPressedThisFrame)
                TryExitActiveVehicle();
        }

        public void BlockExitForDuration()
        {
            float newIgnoreTime = Time.unscaledTime + Mathf.Max(0f, _exitBlockDuration);
            if (newIgnoreTime > _ignoreExitUntilTime)
                _ignoreExitUntilTime = newIgnoreTime;
        }

        private void OnInteractStarted(InputAction.CallbackContext _)
        {
            TryExitActiveVehicle();
        }

        private void TryExitActiveVehicle()
        {
            if (_vehicleChanger == null)
                return;

            if (Time.unscaledTime < _ignoreExitUntilTime)
                return;

            if (!_vehicleChanger.characterBased)
                return;

            if (_vehicleChanger.location != VehicleChanger.CharacterLocation.Inside)
                return;

            Vehicle activeVehicle = GetActiveVehicle();
            if (activeVehicle == null)
                return;

            if (activeVehicle.Speed >= _vehicleChanger.maxEnterExitVehicleSpeed)
                return;

            if (_transitionManager != null)
            {
                if (_transitionManager.IsTransitionRunning)
                    return;

                _transitionManager.PlayTransitionToVehicleState(false, () => _vehicleChanger.ExitVehicle(activeVehicle));
            }
            else
            {
                _vehicleChanger.ExitVehicle(activeVehicle);
            }
        }

        private Vehicle GetActiveVehicle()
        {
            int index = _vehicleChanger.activeVehicleIndex;
            if (index < 0 || index >= _vehicleChanger.vehicles.Count)
                return null;

            return _vehicleChanger.vehicles[index];
        }
    }
}
