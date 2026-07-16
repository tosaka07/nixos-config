{
  config,
  lib,
  pkgs,
  ...
}:
{
  # herdr のキーバインドは tmux (modules/home/base/programs/tmux/tmux.nix) の
  # 現行バインドを一旦リスペクトして揃えている。
  # herdr 側の内部詳細 (resize_mode 中の移動キー、矩形選択、mouse 設定など) は
  # 公式ドキュメント (https://herdr.dev/ja/docs/) に明記が少ないため、
  # `herdr --default-config` の出力と突き合わせて随時調整すること。
  xdg.configFile."herdr/config.toml".text = ''
    [keys]
    # tmux の prefix (C-Space) と揃える
    prefix = "ctrl+space"

    # vim ライクなペイン移動 (tmux: bind h/j/k/l select-pane)
    focus_pane_left = "prefix+h"
    focus_pane_down = "prefix+j"
    focus_pane_up = "prefix+k"
    focus_pane_right = "prefix+l"

    # ペイン分割
    # tmux: bind | split-window -h (左右に分割)
    # tmux: bind - split-window -v (上下に分割)
    # herdr の split_horizontal/split_vertical は tmux と向きが逆だったため、
    # キーの割り当てを入れ替えて見た目の挙動を tmux に揃えている
    split_horizontal = "prefix+minus"
    split_vertical = "prefix+|"

    # タブ (tmux のウィンドウ) 移動 (tmux: bind Tab next-window / bind C-Tab previous-window)
    next_tab = "prefix+tab"
    previous_tab = "prefix+ctrl+tab"

    # コピーモード (tmux: keyMode vi の copy-mode-vi 相当)
    # herdr の copy mode は h/j/k/l, w/b/e, {/} で移動、v か Space で選択開始、
    # y か Enter でコピーとなり、tmux の vi キーバインドとほぼ同等
    copy_mode = "prefix+["

    # リサイズモード (tmux: bind -r H/J/K/L resize-pane)
    resize_mode = "prefix+r"

    # ズーム
    zoom = "prefix+z"

    # lazygit をポップアップ起動 (tmux: bind C-g popup ... lazygit)
    [[keys.command]]
    key = "prefix+ctrl+g"
    type = "pane"
    command = "lazygit"
    description = "lazygitを起動"

    [experimental]
    # prefix 押下時に IME を英数入力ソースへ自動切り替えする
    switch_ascii_input_source_in_prefix = true

    # エージェント完了・入力待ちのポップアップ通知
    # terminal 配信: Ghostty など外側のターミナルの通知エスケープシーケンスに委譲する
    [ui.toast]
    delivery = "terminal"
    delay_seconds = 1

    [ui.toast.clipboard]
    enabled = true
    position = "bottom-center"
  '';
}
