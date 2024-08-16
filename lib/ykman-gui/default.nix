{ stdenv, lib, python3, darwin }:

stdenv.mkDerivation
{
  name = "ykman-gui";
  version = "1.0";

  src = ./.;

  buildInputs = [
    (python3.withPackages (py: [
      #  py.tkinter
      py.desktop-notifier
    ]))
  ];


  nativeBuildInputs = [ darwin.autoSignDarwinBinariesHook ];
  # packages = [ pkgs.yubikey-manager ];

  installPhase = ''
    mkdir -pv $out/bin
    cp -v main.py $out/bin/ykman-gui
    chmod -v +x $out/bin/ykman-gui
  '';

  meta = with lib; {
    description = "A simple GUI for YubiKey using ykman";
    license = licenses.mit;
    maintainers = with maintainers; [ "rtlong" ];
  };
}
