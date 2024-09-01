diagrams / inv
----
<pre><code>


╔══════╗
║ ADSB ╟┐
╚╤═════╝│
 └──────┘

 1090
┌────┐
│ 1* ├───┐
└────┘   │
       ┌─┴──┐   ┌────┐   ┌────┐   ┌────┐
       │ 2* ├───┤ 3* ├───┤ 4* ├───┤ 5* │
 978   └─┬──┘   └────┘   └────┘   └────┘
┌────┐   │
│ 1* ├───┘
└────┘

detail list:
------------
1 | RTL-SDR V3 R860 RTL2832U 1PPM TCXO
2 | Nooelec SAWbird+
3 | Nooelec SMA DC Block in-Line
4 | MINI-CIRCUITS ZB4PD1-2000-S+
5 | Signalplus 1090MHz / 978MHz Outdoor Omnidirectional Antenna (12dBi)

supplemental :
--------------
Between 4 & 5 (Either / or):
X | FlightAware Band Pass Signal Filter Dual 978-1090 MHz
X | FlightAware Band Pass Signal Filter 1090 MHz

RTL-SDRs :
----------
1001 | 1090
1002 | 978 UAT


╔═══════╗
║ ACARS ║█
╚═══════╝█
 ▀▀▀▀▀▀▀▀▀

 acars
┌────┐
│ 1* ├───┐
└────┘   │
       ┌─┴──┐   ┌────┐   ┌────┐
       │ 2* ├───┤ 3* ├───┤ 4* │
 vdlm  └─┬──┘   └────┘   └────┘
┌────┐   │
│ 1* ├───┘
└────┘

detail list:
------------
1 | RTL-SDR V4 R828D RTL2832U 1PPM TCXO
2 | Mini-Circuits ZCSC-8-152-S+
3 | Nooelec Flamingo+ FM Bandstop Filter v2 (FM Notch Filter)
4 | DPD Productions VHF Air Vertical Outdoor Base Antenna (2.6dBi)

supplemental :
--------------
X | MINI-CIRCUITS ZFSC-2-372-S +2
X | Myers Engineering VL-1221-383 Fixed Airband Antenna

RTL-SDRs :
----------
2001 | DEC 01
2002 | DEC 02
2003 | VDL2


 hfdl
┌────┐   ┌────┐   ┌────┐   ┌────┐
│ 1* ├───┤ 2* ├───┤ 3* ├───┤ 4* │
└────┘   └────┘   └────┘   └────┘

detail list:
------------
1 | RTL-SDR V4 R828D RTL2832U 1PPM TCXO
2 | Mini-Circuits ZCSC-8-152-S+
3 | Nooelec LaNA HF
4 | Vinnant SWL Shortwave Antenna

RTL-SDRs :
----------
3001 | HFDL10
3002 | HFDL11
3003 | HFDL13
3004 | HFDL17
3005 | HFDL21
3006 | HFDL06
3007 | HFDL05_B
3008 | HFDL05_A


╔═════╗
║ AIS ╠╗
╚╦════╝║
 ╚═════╝

 ais
┌────┐   ┌────┐   ┌────┐   ┌────┐
│ 1* ├───┤ 2* ├───┤ 3* ├───┤ 4* │
└────┘   └────┘   └────┘   └────┘

detail list:
------------
1 | RTL-SDR V4 R828D RTL2832U 1PPM TCXO
2 | Nooelec Flamingo+ FM Bandstop Filter v2 (FM Notch Filter)
3 | Nooelec Lana (lLNA)
4 | Tram WSP1604-1604 (2.5dBi)

supplemental :
--------------
X | Morad HD VHF Marine Antenna (159 MHz VHF-AIS 6dBi)

RTL-SDRs :
----------
4001 | AIS AB
4002 | AIS CD


 ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁
╱╲╱╲╱╳╳╳╳╳╳╳╲╱╲╱╲
╲╱╲╱╲╳╳╳╳╳╳╳╱╲╱╲╱
</code></pre>
