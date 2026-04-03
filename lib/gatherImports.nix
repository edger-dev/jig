folder:
  with builtins;
  map
    (name: "${folder}/${name}")
    (filter (name: name != "default.nix") (attrNames (readDir folder)))
