using UnityEngine.Events;
using UnityEngine;
using System;
using PolymindGames.SaveSystem;

namespace PolymindGames
{
    /// <summary>
    /// Manages the parent character's health and death
    /// </summary>
    [HelpURL("https://polymindgames.gitbook.io/welcome-to-gitbook/qgUktTCVlUDA7CAODZfe/player/modules-and-behaviours/health#health-manager-module")]
    [AddComponentMenu("Polymind Games/Damage/Health Manager")]
    public sealed class HealthManager : MonoBehaviour, IHealthManager, ISaveableComponent, IPoolableListener
    {
        [SerializeField]
        [Tooltip("The starting health of this character (can't be higher than the max health).")]
#if UNITY_EDITOR
        [DynamicRange(nameof(Editor_GetMinHealth), nameof(Editor_GetMaxHealth))]
#endif
        private float _health = 100f;

        [SerializeField, Range(1, 10000f)]
        [Tooltip("The starting max health of this character (can be modified at runtime).")]
#if UNITY_EDITOR
        [OnValueChanged(nameof(Editor_OnMaxHealthChanged))]
#endif
        private float _maxHealth = 100f;

        /// <inheritdoc/>
        public float Health => _health;

        /// <inheritdoc/>
        public float MaxHealth
        {
            get => _maxHealth;
            set
            {
                float clampedValue = Mathf.Max(value, 0f);

                if (Math.Abs(clampedValue - _maxHealth) > HealthExtensions.Threshold)
                {
                    _maxHealth = clampedValue;

                    if (_health > _maxHealth)
                    {
                        float prevHealth = _health;
                        _health = clampedValue;
                        DamageReceived?.Invoke(_health - prevHealth, DamageArgs.Default);
                    }
                }
            }
        }
        
        private bool IsAlive => _health >= HealthExtensions.Threshold;

        /// <inheritdoc/>
        public event DamageReceivedDelegate DamageReceived;
        
        /// <inheritdoc/>
        public event HealthRestoredDelegate HealthRestored;
        
        /// <inheritdoc/>
        public event DeathDelegate Death;
        
        /// <inheritdoc/>
        public event UnityAction Respawn;
        
        /// <inheritdoc/>
        public float RestoreHealth(float value)
        {
            bool wasAlive = IsAlive;
            value = Mathf.Abs(value);
            if (TryChangeHealth(ref value))
            {
                HealthRestored?.Invoke(value);

                if (!wasAlive && IsAlive)
                    Respawn?.Invoke();

                return value;
            }

            return 0f;
        }

        /// <inheritdoc/>
        public float ReceiveDamage(float damage)
        {
            damage = -Mathf.Abs(damage);
            if (IsAlive && TryChangeHealth(ref damage))
            {
                DamageReceived?.Invoke(damage, in DamageArgs.Default);

                if (!IsAlive)
                    Death?.Invoke(in DamageArgs.Default);

                return damage * -1;
            }

            return 0f;
        }

        /// <inheritdoc/>
        public float ReceiveDamage(float damage, in DamageArgs args)
        {
            damage = -Mathf.Abs(damage);
            if (IsAlive && TryChangeHealth(ref damage))
            {
                DamageReceived?.Invoke(damage, in args);

                if (!IsAlive)
                    Death?.Invoke(args);

                return damage * -1;
            }

            return 0f;
        }

        private bool TryChangeHealth(ref float delta)
        {
            if (Mathf.Abs(delta) < HealthExtensions.Threshold)
                return false;

            float prevHealth = _health;
            _health = Mathf.Clamp(_health + delta, 0f, _maxHealth);
            delta = Mathf.Abs(prevHealth - _health);
            return true;
        }

        #region Save & Load
        [Serializable]
        private sealed class SaveData
        {
            public float Health;
            public float MaxHealth;
        }

        void ISaveableComponent.LoadMembers(object data)
        {
            var saveData = (SaveData)data;
            _health = saveData.Health;
            _maxHealth = saveData.MaxHealth;
        }

        object ISaveableComponent.SaveMembers() => new SaveData
        {
            Health = _health,
            MaxHealth = _maxHealth
        };
        #endregion
        
        #region Pooling
        void IPoolableListener.OnAcquired() => RestoreHealth(_maxHealth);
        void IPoolableListener.OnReleased() { }
        #endregion

        #region Editor
#if UNITY_EDITOR
#pragma warning disable CS0628
        protected void Editor_OnMaxHealthChanged() => _health = Mathf.Min(_health, _maxHealth);
        protected float Editor_GetMinHealth() => 0f;
        protected float Editor_GetMaxHealth() => _maxHealth;
#pragma warning restore CS0628
#endif
        #endregion
    }
}