{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  system.defaults.controlcenter = {
    # バッテリーの％表示
    BatteryShowPercentage = true;
    # Menubarの音量表示
    Sound = false;
    # MenubarのBluetooth表示
    Bluetooth = false;
    # MenubarのWi-Fi表示
    AirDrop = false;
    # MenubarのDisplay表示
    Display = false;
    FocusModes = false;
    NowPlaying = false;
  };

  system.defaults.dock = {
    # 自動で閉じる
    autohide = true;
    # 最新の使用状況に基づいてスペースを自動的に並べ替えるかどうか
    mru-spaces = false;
    # 開いてるアプリのみ表示
    static-only = false;
    # アイコンサイズ
    tilesize = 36;
    magnification = true;
    largesize = 54;
    show-recents = false;
    mineffect = "scale";
  };

  system.defaults.finder = {
    # ファイル拡張子表示
    AppleShowAllExtensions = true;
    # 隠しファイル表示
    AppleShowAllFiles = true;
    # デフォルトをカラム表示
    FXPreferredViewStyle = "clmv";
    # パスバー
    ShowPathbar = true;
  };

  system.defaults.menuExtraClock = {
    # 日付表示; 0 = show the date
    ShowDate = 0;
    # 24時間表示
    Show24Hour = true;
    # 週表示
    ShowDayOfWeek = true;
    # 秒表示
    ShowSeconds = true;
    # AM/PM表示
    ShowAMPM = false;
  };

  system.defaults.screencapture = {
    type = "png";
    # Screenshot location
    location = "~/Pictures/Screenshots";
    # name = "Screenshot";
    show-thumbnail = false;
  };

  system.defaults.trackpad = {
    # トラックパッドのタップによるクリックを有効
    Clicking = true;
    # 三本指ドラッグを有効
    TrackpadThreeFingerDrag = true;
  };

  system.keyboard = {
    # CapsLock to Control
    remapCapsLockToControl = true;
    enableKeyMapping = true;
  };

  system.defaults.NSGlobalDomain = {
    # インターフェーススタイル
    AppleInterfaceStyle = "Dark";
    # ファイル拡張子表示
    AppleShowAllExtensions = true;
    # 隠しファイル表示
    AppleShowAllFiles = true;
    # リピート入力認識までの時間
    InitialKeyRepeat = 12;
    # キーリピート
    KeyRepeat = 1;
  };

}
