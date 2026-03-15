using PolymindGames.InputSystem;
using UnityEngine;

namespace PolymindGames.UserInterface
{
    [DefaultExecutionOrder(ExecutionOrderConstants.MonoSingleton)]
    public sealed class MainMenu : MonoBehaviour
    {
        [SerializeField]
        private InputContext _menuContext;
        
        public void QuitGame() => LevelManager.Instance.FadeInAndQuitGame();
        public void RedirectToMultiplayerAddon() => Application.OpenURL("https://assetstore.unity.com/packages/add-ons/multiplayer-stp-survival-template-pro-259841");

        private void OnEnable() => InputManager.Instance.PushContext(_menuContext);
        private void OnDisable() => InputManager.Instance.PopContext(_menuContext);
    }
}