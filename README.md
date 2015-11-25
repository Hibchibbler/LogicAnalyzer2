# LogicAnalyzer2
Revisiting the logic analyzer project.

LogicaAnalyzer2: 5 Things
=========================

Things will probably change
---------------------------

Source Structure
----------------
\LogicAnalyzer2\ClientA
\LogicAnalyzer2\LogicCapture
\LogicAnalyzer2\Kernel



ClientA
-------

This is a piece of software written in C#
that can be used as a frontend. It charts data,
and controls the Hardware.

Logic Capture Hardware
----------------------

This is a piece of hardware written earlier.
It is responsible for storing sample data
into RAM, when certain conditions exist (such
as triggers).


The Kernel
----------

This is primarily two things: 1) The PicoBlaze processor (C&C), 
and 2) the nexus (C&C Hub) through which everything else 
connects. The Logic Capture hardware connects to the hub.
The UARTS connect to the hub. The buttons, switches, 
and LEDs connect to the hub.

![logo](https://raw.github.com/Hibchibbler/LogicAnalyzer2/master/Stuff/Kernel_rev0.png)

