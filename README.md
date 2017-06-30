## Prius Mileage Calculations

Simple script to process mileage and electricity consumption from a
[2017 Prius Prime][Prime], a "plug-in hybird" with 25-30 miles of
electric range plus ~550 miles of gasoline-driven "fallback" range.

I have been curious how much energy the car needs to move about, and
how that compares to gasoline. I pay a fair bit for electricity
(~17.5&#162; / kWh) and wanted to find the "break even point" where
running off gasoline was roughly the same cost per mile as running off
line voltage.

The Prius reports both electrical and fuel consumption metrics, but I
wanted to measure consumption at the outlet. I am using a
[Kill-A-Watt P4400][KillAWatt] to measure kilowatt&middot;hours (kWh)
at the outlet.

Data are noted in [log.txt](log.txt), a simple space-delimited file
that will also be parsed for some constants, like gasoline MPG and
cost of a kWh. It is parsed by [run.R](run.R).

[Prime]: https://en.wikipedia.org/wiki/Toyota_Prius_Plug-in_Hybrid
[KillAWatt]: http://www.p3international.com/products/p4400.html

Current data:
```
Summary statistics:
       Time : 12 days (0.03 years)
  EMV miles : 244.9
  ICE miles : 7.2
        kWh : 64.27
     Mi/kWh : 3.81

        MPG : 54.0

  Cents/kWh : 17.6

 Electicity : $11.31 ($343.89/year)
  BreakEven : $2.49 = Break-even cost of gasoline

```
