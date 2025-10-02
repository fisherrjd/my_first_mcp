{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2025-09-30";
      url = "https://github.com/jpetrucciani/nix/archive/16fbc4bb4483bb5d3c81ee056943e81a60df0e4f.tar.gz";
      sha256 = "0xhyg262xhfixrxlxwpyaaxn484vj5z1h2c41hnhdkh2pxkpb18c";
    })
    { }
}:
let
  name = "my_first_mcp";

  uvEnv = pkgs.uv-nix.mkEnv {
    inherit name; python = pkgs.python313;
    workspaceRoot = pkgs.hax.filterSrc { path = ./.; };
    pyprojectOverrides = final: prev: { };
  };

  tools = with pkgs; {
    cli = [
      jfmt
      nixup
    ];
    uv = [ uv uvEnv ];
    scripts = pkgs.lib.attrsets.attrValues scripts;
  };

  repo = "$(${pkgs.git}/bin/git rev-parse --show-toplevel)";

  scripts = with pkgs; {
    inherit (uvEnv.wrappers) black ruff ty;
    db = pkgs.pog {
      name = "db";
      script = ''
        ${uvEnv}/bin/python -m aggregator.db.data_input
      '';
    };
  };
  paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
  env = pkgs.buildEnv {
    inherit name paths; buildInputs = paths;
  };
in
(env.overrideAttrs (_: {
  inherit name;
  NIXUP = "0.0.9";
  shellHook = ''
    repo="${repo}"
    export PYTHONPATH="$repo:$PYTHONPATH"
    ln -sf ${uvEnv.uvEnvVars._UV_SITE} .direnv/site
  '';
} // uvEnv.uvEnvVars)) // { inherit scripts; }
