using PolymindGames.ProceduralMotion;
using PolymindGames.PoolingSystem;
using UnityEngine;

namespace PolymindGames.Demo
{
    public sealed class DebrisFader : MonoBehaviour, IPoolableListener
    {
        [SerializeField]
        private bool _autoStart = true;

        [SerializeField, NotNull, SpaceArea]
        private Material _materialTemplate;

        [SpaceArea]
        [SerializeField, Range(0f, 60f)]
        private float _fadeDelay = 1f;

        [SerializeField, Range(0.01f, 60f)]
        private float _fadeDuration = 10f;

        [SerializeField]
        private EaseType _fadeEaseType;

        private MeshRenderer[] _renderers;
        private Material _pooledMaterial;
        private Poolable _poolable;

        public void StartFading()
        {
            if (_pooledMaterial == null || !_pooledMaterial.HasActiveTweens())
                Fade();
        }

        private void Awake()
        {
            _renderers = GetComponentsInChildren<MeshRenderer>(true);
            _poolable = GetComponent<Poolable>();

            if (_renderers.Length == 0)
            {
                Debug.LogError("No renderers found for this debris fader.");
                return;
            }

            if (!PoolManager.Instance.HasPool(_materialTemplate))
            {
                PoolManager.Instance.RegisterPool(_materialTemplate, new GenericObjectPool<Material>(
                    createFunc: () =>
                    {
                        var instance = new Material(_materialTemplate)
                        {
                            name = _materialTemplate.name + " - Clone",
                            color = _materialTemplate.color.WithAlpha(1f)
                        };
                        return instance;
                    },
                    actionOnGet: (instance) => instance.color = instance.color.WithAlpha(1f),
                    null,
                    null,
                    2,
                    4));
            }
        }

        private void OnEnable()
        {
            if (_poolable == null && _autoStart)
                Fade();
        }

        private void OnDisable()
        {
            if (_pooledMaterial != null && _pooledMaterial.ClearTweens())
                Release();
        }

        private void Fade()
        {
            _pooledMaterial = PoolManager.Instance.Get(_materialTemplate);

            foreach (var meshRenderer in _renderers)
                meshRenderer.sharedMaterial = _pooledMaterial;

            Color color = _pooledMaterial.color;
            _pooledMaterial.TweenMaterialColor(color.WithAlpha(0f), _fadeDuration)
                .SetStartValue(color.WithAlpha(1f))
                .OnComplete(Release)
                .SetDelay(_fadeDelay)
                .SetEasing(_fadeEaseType);
        }

        private void Release()
        {
            if (_poolable != null)
                _poolable.Release();
            else
            {
                Destroy(gameObject);
                OnReleased();
            }
        }

        #region Pooling
        public void OnAcquired()
        {
            if (_autoStart)
                Fade();
        }

        public void OnReleased()
        {
            _pooledMaterial.ClearTweens();
            PoolManager.Instance.Release(_materialTemplate, _pooledMaterial);
        }
        #endregion

        #region Editor
#if UNITY_EDITOR
        private void Reset()
        {
            gameObject.SetLayersInChildren(LayerConstants.Debris);
        }
#endif
        #endregion
    }
}