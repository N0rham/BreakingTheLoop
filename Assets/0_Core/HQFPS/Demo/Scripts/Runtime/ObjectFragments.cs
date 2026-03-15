using UnityEngine;
using System;

namespace PolymindGames.Demo
{
    public sealed class ObjectFragments : MonoBehaviour
    {
        [SerializeField]
        private AudioData _audio = new(null);

        [SerializeField, ChildObjectOnly]
        private ParticleSystem _particles;

        [SerializeField, Range(0f, 100f)]
        private float _forceMultiplier = 1f;

        [SpaceArea]
#if UNITY_EDITOR
        [EditorButton(nameof(GetAllFragments_EDITOR))]
#endif
        [SerializeField, ReorderableList(elementLabel: "Fragment")]
        private RigidbodyInfo[] _fragments;

        public void ExplodeFragments(in DamageArgs args)
        {
            AudioManager.Instance.PlayClip3D(_audio, args.HitPoint);
            CoroutineUtility.InvokeNextFrame(this, AddForces, args);

            if (_particles != null)
                _particles.Play(true);
        }

        private void AddForces(DamageArgs args)
        {
            float forceMod = args.HitForce.magnitude / _fragments.Length * _forceMultiplier;
            foreach (var rigidbodyInfo in _fragments)
            {
                var rigidB = rigidbodyInfo.Rigidbody;
                Vector3 force = args.HitForce.normalized * forceMod;
                rigidB.AddForce(force, ForceMode.Impulse);
                rigidB.AddExplosionForce(forceMod, args.HitPoint, 5, 1f);
            }
        }

        private void OnDisable()
        {
            foreach (var rigidbodyInfo in _fragments)
            {
                var rigidbodyTrs = rigidbodyInfo.Rigidbody.transform;
                rigidbodyTrs.localPosition = rigidbodyInfo.OriginalPosition;
                rigidbodyTrs.localEulerAngles = rigidbodyInfo.OriginalRotation;
            }
        }

        #region Internal Types
        [Serializable]
        private struct RigidbodyInfo
        {
            public Rigidbody Rigidbody;
            public Vector3 OriginalPosition;
            public Vector3 OriginalRotation;

            public RigidbodyInfo(Rigidbody rigidbody, Vector3 originalPosition, Vector3 originalRotation)
            {
                Rigidbody = rigidbody;
                OriginalPosition = originalPosition;
                OriginalRotation = originalRotation;
            }
        }
        #endregion

        #region Editor
#if UNITY_EDITOR
        private void GetAllFragments_EDITOR()
        {
            var rigidbodies = transform.GetComponentsInChildren<Rigidbody>(true);
            _fragments = new RigidbodyInfo[rigidbodies.Length];

            for (int i = 0; i < rigidbodies.Length; i++)
                _fragments[i] = new RigidbodyInfo(rigidbodies[i], rigidbodies[i].transform.localPosition, rigidbodies[i].transform.localEulerAngles);

            UnityEditor.EditorUtility.SetDirty(this);
        }
#endif
        #endregion
    }
}