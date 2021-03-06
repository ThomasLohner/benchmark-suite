# Benchmark-Suite

#### Table of Contents
1. [Overview](#overview)
2. [Description - Wozu ist das nützich?](#description)
3. [Compatibility - Wo kann ich es einsetzen?](#compatibility)
4. [Setup - Wie wird die Software installiert?](#setup)
5. [Software - Was wird alles installiert?](#software)
6. [Benchmark - Wie wird getestet?](#benchmark)
    * [Magento](#magento)
    * [Unattended Benchmarks](#unattended-benchmarks)
7. [Roadmap - Was fehlt bisher?](#roadmap-todos)

## Overview
Die Benchmark-Suite ist eine einfach zu installierende Sammlung von Benchmark-Tools und Web-Applikationen.

## Description
Diese Skriptsammlung installiert und konfiguriert alle benötigten Dienste und Tools für Percmonace- und Lasttests im LAMP-Stack. Da es keine externen Abhängigkeiten gibt, eigent sich diese Benchmark-Suite vor allem zum Vergleich von VMs bei unterschiedlichen Providern. Es lassen sich aber auch verschiedene Plattform-Technologien bzw. Tuning-Parameter gegeneinander testen. 

## Compatibility
Für **Ubuntu** und **Gentoo** gibt es ein All-In-One Installations-Script mit Autodection der Linux-Distribution. Die Software-Pakete werden mit lokalen Puppet-Manifesten installiert und konfiguriert. Es sollen ganz bewusst keine externen Abhängigkeiten benutzt werden, wie zum Beispiel ein Puppet-Master oder unnötige Module.

## Setup
Das Script `install.sh` erkennt die Linux-Distribution und installiert alle Abhängigkeiten. Anschließend werden Softwarepakete per Puppet installiert konfiguriert. Im letzten Schritt werden Webapplikationen im DocRoot des Apache-vhosts installiert.

    sudo -s
    su -
    bash <(curl -s https://gitlab.syseleven.de/t.lohner/benchmark/raw/master/install.sh)



## Benchmark
Für Webapplikationen werden zufällige Passwörter generiert. Nach der Installation können die Benchmarks mit den üblichen Tools durchgeführt werden.

### Magento

	 ___________________________________________________________________________________________________________ 
	/                                                                                                           \
	| I've installed magento at:                                                                                |
	|                                                                                                           |
	| http://www.invaliddomain.de/magento/                                                                      |
	|                                                                                                           |
	| MySQL Credentials:                                                                                        |
	| User: mage                                                                                                |
	| Pass: oXee0AeheiPh                                                                                        |
	| Host: 10.4.161.7                                                                                          |
	| DB:   magento                                                                                             |
	|                                                                                                           |
	| Remember to add this line to your local /etc/hosts-file:                                                  |
	| 37.44.0.2  www.invaliddomain.de                                                                           |
	|                                                                                                           |
	| Start benchmarking with:                                                                                  |
	|                                                                                                           |
	| ab -c 1 -t 60 http://www.invaliddomain.de/magento/catalogsearch/result/?q=dress                           |
	|                                                                                                           |
	| siege -v -b -c 1 -t 60S --log=/dev/null http://www.invaliddomain.de/magento/catalogsearch/result/?q=dress |
	|                                                                                                           |
	\                                                                                                           /
	 ----------------------------------------------------------------------------------------------------------- 
	        \   ^__^
	         \  (oo)\_______
	            (__)\       )\/\
	                ||----w |
	                ||     ||


### Unattended Benchmarks
Dank CloudInit und dem All-In-One-Installer können wir unbeaufsichtigt und komplett automatisiert zufällige Load in einer Plattform erzeugen. Die Messwerte verfallen zwar, weil es bisher keine zentrale API zum Sammeln der Daten gibt, aber für Load-Tests ist die Suite gut geeigent. Dazu werden beliebig viele Instanzen mit folgendem Post-Install-Script gestartet.
*Bitte die Anzahl der Instanzen vorsichtig wählen ;-)*
```bash
#!/usr/bin/env bash

passwd ubuntu <<EOF
GanzGeheim!!11elf
GanzGeheim!!11elf
EOF

/bin/bash <(curl -s https://gitlab.syseleven.de/t.lohner/benchmark/raw/master/install.sh) >>/tmp/benchlog 2>&1

/usr/bin/siege -v -b -c $(/usr/bin/nproc) -t 30M --log=/tmp/benchlog http://www.invaliddomain.de/magento/catalogsearch/result/?q=dress >>/tmp/benchlog 2>&1

```

## Software
Die Benchmark-Suite installiert folgende Tools und Software-Pakete:

* PHP 5.6
* Apache 2.4
* Percona Server 5.6
* Magento CE mit Sample Data
* ab (Apache Bench)
* siege
* ioping
* cowsay ;-)

## Roadmap / Todos
Das ist die erste, sehr rudimentäre Version einer Benchmark-Suite. Es gitb viele Dinge, die hier erweitert oder verbessert werden können:
* Parameter für`install.sh`um z.B. getrennte App- und DB-Server zu installieren
* Fehler-Behandlung nach jedem Schritt mit Wiederhol-Funktion
* Prüfung ob DB und DocRoot schon existieren und Funktion für Re-Install
* Weitere Dienste (elasticsearch, redis, usw.)
* Weitere Webapplikationen (OXID, Shopware, Wordpress)
* Weitere Benchmarks (sysbench, iperf, bonnie++, pipebench)
* Zentrale GUI, an die Benchmark-Ergebnisse per API geschickt werden
* Magento-Installer verbessern, damit das Scirpt auch bei Einrichtungen benutzt werden kann (Übergabe an Kunden mit funktionieremdem Shop)
