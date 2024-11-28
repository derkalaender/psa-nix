{
  imports = map (module: ./${module}) (
    builtins.filter 
      (name: builtins.pathExists (./. + "/${name}/default.nix"))
      (builtins.attrNames (builtins.readDir ./.))
  );
}
