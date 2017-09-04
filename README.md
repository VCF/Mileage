## Prius Mileage Calculations

Simple script to process mileage and electricity consumption from a
[2017 Prius Prime][Prime], a "plug-in hybird" with 25-30 miles of
electric range plus ~550 miles of gasoline-driven "fallback" range.

I have been curious how much energy the car needs to move about, and
how that compares to gasoline. I pay a fair bit for electricity
(~17.5&#162; / kWh - [BLS regional rates][BLS]) and wanted to find the
"break even point" where running off gasoline was roughly the same
cost per mile as running off line voltage.

The Prius reports both electrical and fuel consumption metrics, but I
wanted to measure consumption at the outlet. I am using a
[Kill-A-Watt P4400][KillAWatt] to measure kilowatt&middot;hours (kWh)
at the outlet.

Data are noted in [log.txt](log.txt), a simple space-delimited file
that will also be parsed for some constants, like gasoline MPG and
cost of a kWh. It is parsed by [run.R](run.R).

[Prime]: https://en.wikipedia.org/wiki/Toyota_Prius_Plug-in_Hybrid
[KillAWatt]: http://www.p3international.com/products/p4400.html
[BLS]: https://www.bls.gov/regions/new-york-new-jersey/news-release/averageenergyprices_newyorkarea.htm

Current data (EMV=Electric vehicle, ICE=Gasoline):
```
Summary statistics:
       Time : 77 days (0.21 years)
  EMV miles : 1417.0
  ICE miles : 69.6
Consumption : 378.57 kWh
    Mileage : 3.72 Mi/kWh
   Capacity : 7.31 kWh
      Range : 27.2 miles
        MPG : 54.0
  Cents/kWh : 17.6
 Electicity : $66.60 ($315.68/year)
  BreakEven : $2.55/gal = Equivalent cost of gasoline

```


### Mileage Variation

[Mileage Histogram](Mileage.png)

The above plot shows variation in mileage over different trips. The
IQR is the [interquartile range][IQR], and is used here to exclude
outliers (very low or high values, which occur either due to typos or
because I needed to take a second trip before the battery fully
charged - the first trip will seem to have a high mileage, the second
a low one). The average mileage is calculated from only the values in
the IQR.

The "Break even" price is the point at which the cost of using
electricity is identical to the cost of running the car on
gasoline. This is a simplistic measure, in that it does not take into
account differences in maintenance costs of the two power sources,
time costs (driving to a gas station every few weeks
vs. connecting/disconnecting the charger every trip). But I think it's
a valuable comparative value.

[IQR]: https://en.wikipedia.org/wiki/Interquartile_range
