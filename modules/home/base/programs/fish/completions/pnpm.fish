function __pnpm_run_script_completions
    if not test -f package.json
        return 1
    end

    if command -q jq
        jq -r '.scripts // {} | to_entries[] | "\(.key)\t\(.value)"' package.json 2>/dev/null
        return $status
    end

    if command -q node
        node -e '
            const fs = require("fs");
            try {
              const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
              for (const [name, script] of Object.entries(pkg.scripts || {})) {
                console.log(`${name}\t${script}`);
              }
            } catch {
              process.exit(1);
            }
        ' 2>/dev/null
        return $status
    end

    return 1
end

function __pnpm_should_complete_run_scripts
    set -l tokens (commandline -xpc)

    if not set -q tokens[1]
        return 1
    end

    if test "$tokens[1]" != pnpm
        return 1
    end

    if not set -q tokens[2]
        return 1
    end

    if not contains -- $tokens[2] run run-script
        return 1
    end

    test (count $tokens) -eq 2
end

function _pnpm_completion
    if __pnpm_should_complete_run_scripts
        set -l scripts (__pnpm_run_script_completions)
        if set -q scripts[1]
            printf "%s\n" $scripts
            return 0
        end
    end

    set -l cmd (commandline -o)
    set -l cursor (commandline -C)
    set -l words (count $cmd)

    set -l completions (eval env DEBUG=\"" \"" COMP_CWORD=\""$words\"" COMP_LINE=\""$cmd \"" COMP_POINT=\""$cursor\"" SHELL=fish pnpm completion-server -- $cmd)

    if test "$completions" = "__tabtab_complete_files__"
        set -l matches (commandline -ct)*
        if test -n "$matches"
            __fish_complete_path (commandline -ct)
        end
    else
        for completion in $completions
            echo -e $completion
        end
    end
end

complete -f -d 'pnpm' -c pnpm -a "(_pnpm_completion)"
