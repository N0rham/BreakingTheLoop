using NWH.Common.Input;
using UnityEngine;

namespace BtlGame.VehicleInteraction
{
    [DisallowMultipleComponent]
    public sealed class InteractSceneInputProvider : SceneInputProviderBase
    {
        private static bool _pendingChangeVehicle;

        public static void RequestChangeVehicle()
        {
            _pendingChangeVehicle = true;
        }

        public override bool ChangeVehicle()
        {
            if (!_pendingChangeVehicle)
                return false;

            _pendingChangeVehicle = false;
            return true;
        }
    }
}
