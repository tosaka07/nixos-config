{
  config,
  lib,
  pkgs,
  ...
}:
{
  # IME切り替えキーボードショートカットの設定
  system.activationScripts.inputSource.text = ''
    # Spotlight のCmd+Spaceを無効化
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'

    # IME切り替えをCmd+Spaceに設定
    /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'

    # 設定を再読み込み
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Siriの無効化設定
  system.activationScripts.siri.text = ''
    # Siriのメニューバー表示を無効化
    /usr/bin/defaults write com.apple.Siri SiriPrefStashedStatusMenuVisible -bool false

    # Siriの音声トリガーを無効化
    /usr/bin/defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
  '';

}
