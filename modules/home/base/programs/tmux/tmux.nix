{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Install tmux scripts using xdg.configFile
  xdg.configFile."tmux/scripts/worktree.sh" = {
    source = ./worktree.sh;
    executable = true;
  };

  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    mouse = true;
    historyLimit = 5000;
    keyMode = "vi";
    baseIndex = 1;
    plugins = with pkgs; [
      tmuxPlugins.tmux-fzf
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g default-terminal "tmux-256color"

          set -g @catppuccin_flavour 'mocha'
          set -g @catppuccin_status_background 'default'
          set -g status-right-length 200
          set -g status-left-length 100
          set -g status-left ""

          # Reset status-right before setting catppuccin modules
          set -g status-right ""
          set -ag status-right "#{E:@catppuccin_status_application}"
          set -ag status-right "#{E:@catppuccin_status_user}"
          set -ag status-right "#{E:@catppuccin_status_host}"
          set -ag status-right "#{E:@catppuccin_status_session}"
        '';
      }
    ];
    extraConfig = ''
      # vimのキーバインドでペインを移動する
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # vimのキーバインドでペインをリサイズする
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      bind -r O rotate-window -D

      # キーストロークのディレイを減らす
      set -sg escape-time 0

      # | ペインを縦分割する
      bind | split-window -h -c '#{pane_current_path}'

      # - ペインを縦分割する
      bind - split-window -v -c '#{pane_current_path}'

      # Tab ウィンドウを移動
      bind Tab next-window
      bind C-Tab previous-window

      # 'v' 選択を始める
      bind -T copy-mode-vi v send -X begin-selection

      # 'V' 行選択
      bind -T copy-mode-vi V send -X select-line

      # 'C-v' 矩形選択
      bind -T copy-mode-vi C-v send -X rectangle-toggle

      # 'y' ヤンク
      bind -T copy-mode-vi y send -X copy-selection

      # 'Y' 行ヤンク
      bind -T copy-mode-vi Y send -X copy-line

      # 'C-p'ペースト
      bind-key C-p paste-buffer

      # 'c-r' 設定リロード
      bind R source '~/.config/tmux/tmux.conf'

      # 'c-g' lazygitを起動
      bind C-g popup -xC -yC -w90% -h90% -E -d "#{pane_current_path}" -e "TMUX_POPUP=1" -e "TMUX_PARENT_PANE=#{pane_id}" "lazygit"

      bind C-i popup -xC -yC -w90% -h90% -d "#{pane_current_path}" -e "TMUX_POPUP=1" -e "TMUX_PARENT_PANE=#{pane_id}"

      # 'C-w' git worktreeを選択/作成
      bind C-w popup -xC -yC -w90% -h90% -E -d "#{pane_current_path}" "~/.config/tmux/scripts/worktree.sh"

      TMUX_FZF_LAUNCH_KEY="C-f"

      # ステータスバー
      set -g status-position top
      set-option -g status-interval 1

      # ウィンドウを閉じた時に番号を詰める
      set-option -g renumber-windows on

      set-option -s escape-time 0
      set-option -g display-time 4000
      set-option -g focus-events on
    '';
  };
}
