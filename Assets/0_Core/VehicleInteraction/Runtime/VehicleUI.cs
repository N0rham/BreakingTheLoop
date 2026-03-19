using NWH.Common.Vehicles;
using NWH.VehiclePhysics2;
using NWH.VehiclePhysics2.VehicleGUI;
using UnityEngine;

namespace BtlGame.VehicleInteraction
{
    /// <summary>
    /// Minimal vehicle HUD updater for speed, RPM, and turn signals only.
    /// </summary>
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Canvas))]
    public sealed class VehicleUI : MonoBehaviour
    {
        [Header("Vehicle Source")]
        [SerializeField]
        private bool _useActiveVehicle = true;

        [SerializeField]
        private VehicleController _vehicleController;

        [Header("Gauges")]
        [SerializeField]
        private AnalogGauge _analogSpeedGauge;

        [SerializeField]
        private AnalogGauge _analogRpmGauge;

        [SerializeField]
        private bool _speedInKph = true;

        [Header("Turn Signals")]
        [SerializeField]
        private DashLight _leftTurnSignal;

        [SerializeField]
        private DashLight _rightTurnSignal;

        [Header("Lights")]
        [SerializeField]
        private DashLight _headlightSignal;

        private void Update()
        {
            VehicleController vc = ResolveVehicleController();
            if (vc == null)
            {
                ResetUi();
                return;
            }

            float speed = vc.Speed * (_speedInKph ? 3.6f : 2.2369363f);
            float rpm = vc.powertrain != null && vc.powertrain.engine != null
                ? vc.powertrain.engine.OutputRPM
                : 0f;

            if (_analogSpeedGauge != null)
            {
                _analogSpeedGauge.Value = speed;
            }

            if (_analogRpmGauge != null)
            {
                _analogRpmGauge.Value = rpm;
            }

            bool leftOn = vc.effectsManager != null
                          && vc.effectsManager.lightsManager != null
                          && vc.effectsManager.lightsManager.leftBlinkers != null
                          && vc.effectsManager.lightsManager.leftBlinkers.On;

            bool rightOn = vc.effectsManager != null
                           && vc.effectsManager.lightsManager != null
                           && vc.effectsManager.lightsManager.rightBlinkers != null
                           && vc.effectsManager.lightsManager.rightBlinkers.On;

            bool headlightsOn = vc.effectsManager != null
                                && vc.effectsManager.lightsManager != null
                                && ((vc.effectsManager.lightsManager.lowBeamLights != null
                                     && vc.effectsManager.lightsManager.lowBeamLights.On)
                                    || (vc.effectsManager.lightsManager.highBeamLights != null
                                        && vc.effectsManager.lightsManager.highBeamLights.On));

            if (_leftTurnSignal != null)
            {
                _leftTurnSignal.Active = leftOn;
            }

            if (_rightTurnSignal != null)
            {
                _rightTurnSignal.Active = rightOn;
            }

            if (_headlightSignal != null)
            {
                _headlightSignal.Active = headlightsOn;
            }
        }

        private VehicleController ResolveVehicleController()
        {
            if (_useActiveVehicle)
            {
                _vehicleController = Vehicle.ActiveVehicle as VehicleController;
            }

            return _vehicleController;
        }

        private void ResetUi()
        {
            if (_analogSpeedGauge != null)
            {
                _analogSpeedGauge.Value = 0f;
            }

            if (_analogRpmGauge != null)
            {
                _analogRpmGauge.Value = 0f;
            }

            if (_leftTurnSignal != null)
            {
                _leftTurnSignal.Active = false;
            }

            if (_rightTurnSignal != null)
            {
                _rightTurnSignal.Active = false;
            }

            if (_headlightSignal != null)
            {
                _headlightSignal.Active = false;
            }
        }
    }
}
