using PolymindGames.PoolingSystem;
using UnityEngine.Events;
using UnityEngine;

namespace PolymindGames.Demo
{
    [RequireComponent(typeof(IHealthManager))]
    public sealed class FragmentableObject : MonoBehaviour
    {
        [SerializeField, PrefabObjectOnly]
        private ObjectFragments _fragmentsPrefab;

        [SerializeField, SpaceArea]
        private UnityEvent<ICharacter> _breakEvent;

        private void BreakObject(in DamageArgs args)
        {
            _breakEvent.Invoke(args.Source as ICharacter);
            transform.GetPositionAndRotation(out var position, out var rotation);
            Release();
            PoolManager.Instance.Get(_fragmentsPrefab, position, rotation).ExplodeFragments(args);
        }

        private void Release()
        {
            if (TryGetComponent(out Poolable poolable))
            {
                poolable.Release();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            if (!PoolManager.Instance.HasPool(_fragmentsPrefab))
            {
                PoolManager.Instance.RegisterPool(_fragmentsPrefab,
                    new SceneObjectPool<ObjectFragments>(_fragmentsPrefab, gameObject.scene, PoolCategory.Debris, 2, 6));
            }

            var healthManager = GetComponent<IHealthManager>();
            healthManager.Death += BreakObject;
        }

        #region Editor Logic
#if UNITY_EDITOR
        private void Reset()
        {
            if (!gameObject.HasComponent<IHealthManager>())
                gameObject.AddComponent(typeof(HealthManager));
        }
#endif
        #endregion
    }
}