{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "openldap_exporter";
  version = "2.2.4";

  src = fetchFromGitHub {
    rev = "v${version}";
    owner = "ml0renz0";
    repo = "openldap_exporter";
    sha256 = "sha256-4tMoD3PaWX8P5/3vJ4PAEUEZ5uAtFX0RX52/YmhAdTA=";
  };

  vendorHash = null;

  meta = with lib; {
    description = "Prometheus exporter for OpenLDAP";
    mainProgram = "openldap_exporter";
    homepage = "https://github.com/tomcz/openldap_exporter";
    license = licenses.mit;
  };
}
