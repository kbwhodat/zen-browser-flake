{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  version,
  url,
  hash,
  policies ? { },
  nativeMessagingHosts ? [],
  ...
}:
let
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "zen-browser-bin-darwin";
  inherit version;

  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [
    pkgs._7zz
    pkgs.undmg
  ] ++ nativeMessagingHosts;

  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  unpackPhase = ''
    runHook preUnpack

    undmg $src || 7zz x -snld $src

    runHook postUnpack
  '';

  installPhase =
    ''
      runHook preInstall

      mkdir -p "$out/Applications/${sourceRoot}"
      cp -R . "$out/Applications/${sourceRoot}"

      runHook postInstall
    ''
    + (
      if isPoliciesEnabled then
        ''
          mkdir -p "$out/Applications/Zen Browser.app/Contents/Resources/distribution"
          echo '${policiesJson}' > "$out/Applications/Zen Browser.app/Contents/Resources/distribution/policies.json"
        ''
      else
        ""
    );

  postFixup =
    ''
      wrapProgram "$out/Applications/Zen Browser.app/Contents/MacOS/zen" --add-flags "--ProfileManager %u"
    '';

  src = fetchurl {
    name = "Zen Browser-${version}.dmg";
    inherit url hash;
  };

  meta = {
    mainProgram = "zen";
    description = "Zen Browser binary package for macOS";
    homepage = "https://www.zen-browser.app/";
    platforms = lib.platforms.darwin;
  };
}
