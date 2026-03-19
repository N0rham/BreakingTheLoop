using System.Collections;
using System;
using NWH.Common.SceneManagement;
using UnityEngine;

namespace BtlGame.VehicleInteraction
{
    /// <summary>
    /// Handles vehicle HUD visibility and black screen fade transitions when entering or exiting a vehicle.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class VehicleUiTransitionManager : MonoBehaviour
    {
        [Header("References")]
        [SerializeField]
        private VehicleChanger _vehicleChanger;

        [SerializeField]
        [Tooltip("CanvasGroup on the vehicle HUD canvas.")]
        private CanvasGroup _vehicleUiCanvasGroup;

        [SerializeField]
        [Tooltip("CanvasGroup on the black fullscreen overlay.")]
        private CanvasGroup _blackFadeCanvasGroup;

        [Header("Transition")]
        [SerializeField]
        [Min(0f)]
        private float _fadeToBlackDuration = 0.25f;

        [SerializeField]
        [Min(0f)]
        private float _blackHoldDuration = 0.08f;

        [SerializeField]
        [Min(0f)]
        private float _fadeFromBlackDuration = 0.25f;

        [SerializeField]
        [Min(0f)]
        private float _vehicleUiFadeDuration = 0.2f;

        [SerializeField]
        [Tooltip("When enabled, manager auto-detects VehicleChanger location changes and plays transitions automatically.")]
        private bool _autoDetectStateChanges;

        [SerializeField]
        private bool _useUnscaledTime = true;

        private bool _initialized;
        private bool _lastInsideVehicle;
        private Coroutine _transitionCoroutine;

        public bool IsTransitionRunning => _transitionCoroutine != null;

        private void Awake()
        {
            ResolveVehicleChangerIfNeeded();

            if (_blackFadeCanvasGroup != null)
            {
                SetCanvasGroupAlpha(_blackFadeCanvasGroup, 0f);
                _blackFadeCanvasGroup.blocksRaycasts = false;
                _blackFadeCanvasGroup.interactable = false;
            }
        }

        private void Update()
        {
            ResolveVehicleChangerIfNeeded();
            if (_vehicleChanger == null)
                return;

            bool insideVehicle = _vehicleChanger.location == VehicleChanger.CharacterLocation.Inside;
            if (!_initialized)
            {
                _initialized = true;
                _lastInsideVehicle = insideVehicle;
                ApplyVehicleUiStateImmediate(insideVehicle);
                return;
            }

            if (!_autoDetectStateChanges || _transitionCoroutine != null)
                return;

            if (insideVehicle == _lastInsideVehicle)
                return;

            PlayTransitionToVehicleState(insideVehicle, null);
        }

        public void PlayTransitionToVehicleState(bool insideVehicle, Action switchStateAction)
        {
            if (_transitionCoroutine != null)
                StopCoroutine(_transitionCoroutine);

            _transitionCoroutine = StartCoroutine(PlayTransition(insideVehicle, switchStateAction));
        }

        private IEnumerator PlayTransition(bool insideVehicle, Action switchStateAction)
        {
            if (!insideVehicle)
            {
                // Exit flow: hide vehicle UI first, then transition to black.
                yield return FadeVehicleUi(false);
            }

            if (_blackFadeCanvasGroup != null)
            {
                yield return FadeCanvasGroup(_blackFadeCanvasGroup, 1f, _fadeToBlackDuration);

                if (_blackHoldDuration > 0f)
                    yield return Wait(_blackHoldDuration);
            }

            switchStateAction?.Invoke();

            if (_blackFadeCanvasGroup != null)
            {
                yield return FadeCanvasGroup(_blackFadeCanvasGroup, 0f, _fadeFromBlackDuration);
                _blackFadeCanvasGroup.blocksRaycasts = false;
                _blackFadeCanvasGroup.interactable = false;
            }

            if (insideVehicle)
            {
                // Enter flow: show vehicle UI after coming back from black.
                yield return FadeVehicleUi(true);
            }

            _lastInsideVehicle = insideVehicle;
            _initialized = true;

            _transitionCoroutine = null;
        }

        private IEnumerator FadeVehicleUi(bool insideVehicle)
        {
            if (_vehicleUiCanvasGroup == null)
                yield break;

            yield return FadeCanvasGroup(_vehicleUiCanvasGroup, insideVehicle ? 1f : 0f, _vehicleUiFadeDuration);
            _vehicleUiCanvasGroup.blocksRaycasts = insideVehicle;
            _vehicleUiCanvasGroup.interactable = insideVehicle;
        }

        private IEnumerator FadeCanvasGroup(CanvasGroup canvasGroup, float targetAlpha, float duration)
        {
            if (canvasGroup == null)
                yield break;

            if (duration <= 0f)
            {
                SetCanvasGroupAlpha(canvasGroup, targetAlpha);
                canvasGroup.blocksRaycasts = targetAlpha > 0.001f;
                canvasGroup.interactable = targetAlpha > 0.001f;
                yield break;
            }

            float startAlpha = canvasGroup.alpha;
            float elapsed = 0f;

            while (elapsed < duration)
            {
                elapsed += DeltaTime();
                float t = Mathf.Clamp01(elapsed / duration);
                float a = Mathf.Lerp(startAlpha, targetAlpha, t);
                SetCanvasGroupAlpha(canvasGroup, a);
                yield return null;
            }

            SetCanvasGroupAlpha(canvasGroup, targetAlpha);
            bool visible = targetAlpha > 0.001f;
            canvasGroup.blocksRaycasts = visible;
            canvasGroup.interactable = visible;
        }

        private void ApplyVehicleUiStateImmediate(bool insideVehicle)
        {
            if (_vehicleUiCanvasGroup == null)
                return;

            float alpha = insideVehicle ? 1f : 0f;
            SetCanvasGroupAlpha(_vehicleUiCanvasGroup, alpha);
            _vehicleUiCanvasGroup.blocksRaycasts = insideVehicle;
            _vehicleUiCanvasGroup.interactable = insideVehicle;
        }

        private void ResolveVehicleChangerIfNeeded()
        {
            if (_vehicleChanger != null)
                return;

            _vehicleChanger = VehicleChanger.Instance != null
                ? VehicleChanger.Instance
                : FindFirstObjectByType<VehicleChanger>();
        }

        private float DeltaTime()
        {
            return _useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime;
        }

        private IEnumerator Wait(float duration)
        {
            if (_useUnscaledTime)
            {
                float endTime = Time.unscaledTime + duration;
                while (Time.unscaledTime < endTime)
                    yield return null;
            }
            else
            {
                yield return new WaitForSeconds(duration);
            }
        }

        private static void SetCanvasGroupAlpha(CanvasGroup canvasGroup, float alpha)
        {
            canvasGroup.alpha = Mathf.Clamp01(alpha);
        }
    }
}
