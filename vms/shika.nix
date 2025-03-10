{...}: {
  # Wir sind der Router. Dadurch werden...
  # ...statische Netzwerkoptionen konfiguriert (DNS-Server, IP-Adresse, Domain, Routes, ...)
  # ...der DNS & DHCP Server aktiviert
  psa.networking.router = true;

  # Monitoring macht auf dem Router am meisten Sinn, weil er alle Daten sieht
  psa.monitoring.server.enable = true;

  psa.security.ids.enable = true;

  # Pakete sollen weitergeleitet werden
  networking.firewall.allowForwarding = true;

  # Node Exporter Access ist komplett lokal
  psa.monitoring.os.openFirewall = false;

  # Zusätzlich stellen wir noch den hostName statisch fest
  networking.hostName = "vmpsateam06-01";
}
