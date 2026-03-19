using NWH.VehiclePhysics2;
using UnityEngine;

namespace BtlGame.VehicleInteraction
{
    /// <summary>
    /// Diagnostic tool to isolate which vehicle subsystem is causing FPS drops.
    /// Attach to the vehicle and press keys to test different systems.
    /// </summary>
    public class VehiclePerformanceDiagnostic : MonoBehaviour
    {
        private VehicleController _vc;
        private bool _vcEnabledBackup;
        private bool _wheelControllersDisabled = false;
        private bool _rigidbodyKinematicBackup = false;

        private void Start()
        {
            _vc = GetComponent<VehicleController>();
            if (_vc == null)
            {
                Debug.LogError("VehiclePerformanceDiagnostic: VehicleController not found on this GameObject.");
                enabled = false;
                return;
            }

            _vcEnabledBackup = _vc.enabled;
            Debug.Log("=== VehiclePerformanceDiagnostic ===");
            Debug.Log("Press keys to test which system causes FPS drop:");
            Debug.Log("  W - Toggle VehicleController.enabled");
            Debug.Log("  E - Toggle WheelControllers (raycasts)");
            Debug.Log("  Y - Toggle Rigidbody kinematic");
            Debug.Log("  U - Reset all");
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.W))
                ToggleVehicleController();

            if (Input.GetKeyDown(KeyCode.E))
                ToggleWheelControllers();

            if (Input.GetKeyDown(KeyCode.Y))
                ToggleRigidbodyKinematic();

            if (Input.GetKeyDown(KeyCode.U))
                ResetAll();
        }

        private void ToggleVehicleController()
        {
            _vc.enabled = !_vc.enabled;
            Debug.Log($"<color=yellow>VehicleController.enabled = {_vc.enabled}</color>");
        }

        private void ToggleWheelControllers()
        {
            _wheelControllersDisabled = !_wheelControllersDisabled;
            var wheels = _vc.GetComponentsInChildren<NWH.WheelController3D.WheelController>();
            foreach (var wheel in wheels)
                wheel.enabled = !_wheelControllersDisabled;

            Debug.Log($"<color=yellow>WheelControllers.enabled = {!_wheelControllersDisabled} ({wheels.Length} wheels)</color>");
        }

        private void ToggleRigidbodyKinematic()
        {
            _rigidbodyKinematicBackup = !_rigidbodyKinematicBackup;
            _vc.vehicleRigidbody.isKinematic = _rigidbodyKinematicBackup;
            Debug.Log($"<color=yellow>Rigidbody.isKinematic = {_rigidbodyKinematicBackup}</color>");
        }

        private void ResetAll()
        {
            _vc.enabled = _vcEnabledBackup;
            var wheels = _vc.GetComponentsInChildren<NWH.WheelController3D.WheelController>();
            foreach (var wheel in wheels)
                wheel.enabled = true;

            _vc.vehicleRigidbody.isKinematic = false;
            _wheelControllersDisabled = false;
            _rigidbodyKinematicBackup = false;

            Debug.Log("<color=green>All systems reset to defaults.</color>");
        }
    }
}
