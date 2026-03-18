using PolymindGames.PoolingSystem;
using UnityEngine;

namespace PolymindGames.SurfaceSystem
{
    /// <summary>
    /// This script defines a surface effect that manages visual effects.
    /// </summary>
    [RequireComponent(typeof(Poolable))]
    public sealed class SurfaceEffect : MonoBehaviour
    {
        [SerializeField, ReorderableList(HasLabels = false)]
        private ParticleSystem[] _particles;

        private Transform _cachedTransform;

        public void Play(in Vector3 position, in Quaternion rotation, Transform parent = null)
        {
            if (!ReferenceEquals(parent, null))
                _cachedTransform.SetParent(parent);
            
            _cachedTransform.SetPositionAndRotation(position, rotation);

            // Stripped prefab variant refs inside pooled clone-of-clone instances can
            // resolve to null even though the inspector shows them as valid. Detect and
            // heal silently by rebuilding from the live hierarchy.
            for (int i = 0; i < _particles.Length; i++)
            {
                if (_particles[i] == null)
                {
                    RefreshParticles();
                    break;
                }
            }

            for (int i = 0; i < _particles.Length; i++)
                _particles[i].Play(false);
        }

        private void Awake()
        {
            _cachedTransform = transform;
            RefreshParticles();
        }

        private void RefreshParticles()
        {
            if (_particles == null || _particles.Length == 0)
            {
                _particles = GetComponentsInChildren<ParticleSystem>();
                return;
            }

            for (int i = 0; i < _particles.Length; i++)
            {
                if (_particles[i] == null)
                {
                    // A serialized ref failed to resolve (e.g. clone-of-clone pool scenario);
                    // rebuild from the live hierarchy so no particles are silently lost.
                    _particles = GetComponentsInChildren<ParticleSystem>();
                    return;
                }
            }
        }

        #region Editor
#if UNITY_EDITOR
        private void Reset()
        {
            gameObject.layer = LayerConstants.Effect;
        }

        private void OnValidate()
        {
            _particles = GetComponentsInChildren<ParticleSystem>();
            RefreshParticles();
        }
#endif
        #endregion
    }
}