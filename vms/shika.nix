{ ... }:

{
  # Wir sind der Router. Dadurch werden...
  # ...statische Netzwerkoptionen konfiguriert (DNS-Server, IP-Adresse, Domain, Routes, ...)
  # ...der DNS & DHCP Server aktiviert
  psa.networking.router = true;

  # Zusätzlich stellen wir noch den hostName statisch fest
  networking.hostName = "vmpsateam06-01";
}
