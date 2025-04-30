$env.PROMPT_INDICATOR = ""
$env.PROMPT_MULTILINE_INDICATOR = ":::"

$env.PROMPT_COMMAND = {
    let user = $env.USER
    let is_root = ($user == "root")
    let cwd = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
        null => $env.PWD
        '' => '~'
        $relative_pwd => ([~ $relative_pwd] | path join)
    }
    let nix_shell = (
        if ($env.NIX_BUILD_TOP? | is-empty) and ($env.IN_NIX_SHELL? == "1") {
            $"(ansi magenta)[nix-shell](ansi reset) "
        } else {
            ""
        }
    )

    let user_color = if $is_root { ansi red_bold } else { ansi green_bold }
    let dir_color = ansi white
    let reset = ansi reset
    let host = ($env.HOSTNAME? | default (hostname))

    $"($user_color)($user)@($host)($reset) ($nix_shell)($dir_color)($cwd)($reset)> "
}
