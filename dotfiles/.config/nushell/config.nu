# Load environment variables and use a clean prompt
let-env PROMPT_INDICATOR = ""
let-env PROMPT_COMMAND = { || 
    let user = $nu.env.USER
    let is_root = ($user == "root")
    let cwd = (pwd | path basename)
    let nix_shell = (
        if ($nu.env.NIX_BUILD_TOP? | is-empty) and ($nu.env.IN_NIX_SHELL? == "1") {
            $"(ansi magenta)[nix-shell](ansi reset) "
        } else {
            ""
        }
    )

    let user_color = if $is_root { ansi red_bold } else { ansi green_bold }
    let dir_color = ansi cyan_bold
    let reset = ansi reset

    # Example: root@host [nix-shell] ~/dir %
    $"($user_color)($user)@($nu.env.HOSTNAME? | default 'nixos')($reset) ($nix_shell)($dir_color)($cwd)($reset) % "
}
