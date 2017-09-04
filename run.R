library("ggplot2")

file <- "log.txt"

data <- read.delim(file, sep=' ', na.strings=c('-'),
                   comment.char = c('#'), flush=TRUE)

## Ignore last datapoint if it lacks recharge information:
data <- data[ !is.na(data$kWh), ]
np   <- nrow(data)

## Offset structure to calculate deltas; it lacks the last row
offset <- data.frame(Odometer = c(data$Odometer[ -np ]),
                     kWh       = c(data$kWh[ -np ]))
## To make offsets work, remove the first row of data
data <- data[ -1, ]

for (col in colnames(offset)) {
    ## Odometer and watt meter might get reset. If the offset is less
    ## than the data, presume offset to be zero.
    offset[[col]] <- ifelse(offset[[col]] < data[[col]], offset[[col]], 0)
}

## Remove ICE miles from mileage:
offset$Odometer <- ifelse(is.na(data$MilesICE), offset$Odometer,
                           offset$Odometer + data$MilesICE)

## Format date column
data$Date <- as.Date(data$Date, "%Y-%m-%d")

## Calculate per-trip values:
data$MilesEMV     <- data$Odometer - offset$Odometer
data$Consumed     <- data$kWh - offset$kWh
mpkHeader         <- 'Mi/kWh'
data[[mpkHeader]] <- data$MilesEMV / data$Consumed

## Calculate totals:
milesICE <- sum(data$MilesICE, na.rm=TRUE)
milesEMV <- sum(data$MilesEMV, na.rm=TRUE)
totalkWh <- sum(data$Consumed, na.rm=TRUE)
days     <- data$Date[np-1] - data$Date[1] + 1

# What days have multiple runs? These can include data that represent
# partial charges
dupDays  <- data[ duplicated(data$Date), "Date"]
isDup    <- is.element(data$Date, dupDays)

## Alex recommends IQR for outlier identification
mpkVals  <- data[[mpkHeader]]
Q1       <- quantile(mpkVals, 1/4)
Q3       <- quantile(mpkVals, 3/4)
iqrMod   <- 1.5 * (Q3 - Q1)
oddMin   <- signif(Q1 - iqrMod,3)
oddMax   <- signif(Q3 + iqrMod,3)
oddData  <- mpkVals < oddMin | mpkVals > oddMax
outliers <- data[ oddData, ]

## Consider days within 95% of the mpk range and that are not
## duplicated as "trustworthy":
trusty   <- data[ !oddData & !isDup, ]
mpkWh    <- signif(sum(trusty$MilesEMV, na.rm=TRUE) /
                   sum(trusty$Consumed, na.rm=TRUE), 3)

## Days where the battery has been reliably fully depleted
fullUse  <- trusty[ !is.na(trusty$MilesICE), ]
capacity <- mean(fullUse$Consumed)
    
## Display summary stats:
msg <- sprintf("Summary statistics:
       Time : %d days (%.2f years)
  EMV miles : %.1f
  ICE miles : %.1f
Consumption : %.2f kWh
    Mileage : %.2f Mi/kWh
   Capacity : %.2f kWh
      Range : %.1f miles
", days, days / 365, milesEMV, milesICE, totalkWh, mpkWh, capacity,
              capacity * mpkWh )

## See if additional information is embedded in comments
coms <- readLines(file, n=20L)
coms <- coms[ grepl('^#', coms) ] # Fitler for only comments
mpg  <- grepl('Miles per gallon', coms, ignore.case=TRUE)
mpg  <- if (length(mpg) > 0) {
    ## Gasoline mileage
    mpg <- coms[mpg][1]
    mpg <- as.numeric(gsub('.+ ', '', mpg))
    msg <- c(msg, sprintf("        MPG : %.1f\n", mpg))
    mpg
} else {
    54 # Default mileage for ICE, 
}

cpk  <- grepl('Cents per kWh', coms, ignore.case=TRUE)
if (length(cpk) > 0) {
    ## Calculate comparative cost per gallon
    cpk <- coms[cpk][1]
    cpk <- as.numeric(gsub('.+ ', '', cpk))
    msg <- c(msg, sprintf("  Cents/kWh : %.1f\n", cpk))
    kwhPerGal <- mpg / mpkWh # kWH used in distance driven with a gallon
    elecGal   <- cpk * kwhPerGal / 100 # Dollars for a "gallon" of EMV driving
    cost      <- cpk * totalkWh / 100  # Total cost of consumed electricity
    yearly    <- cost * 365 / as.integer(days)     # Average annual cost
    msg <- c(msg, sprintf(" Electicity : $%.2f ($%.2f/year)
  BreakEven : $%.2f/gal = Equivalent cost of gasoline
", cost, yearly, elecGal))
}

if (nrow(outliers) > 0) {
    message("Some days have unusual ", mpkHeader," values:")
    print(outliers)
    message(strrep('-',60))
}

message(msg)

#minDate <- as.numeric(min(data$Date))
#maxDate <- as.numeric(max(data$Date))
minDate  <- -Inf
maxDate  <- Inf
## OMG ggplot's column evaluation is a pain. Specifying 'special characters':
## https://stackoverflow.com/a/19586061
ggplot(data, aes_string(x="Date", y="`Mi/kWh`", ymax=5)) +
    geom_rect(xmin=minDate, xmax=maxDate,
              ymin=oddMin, ymax=oddMax,fill="#ffffaa") +
    geom_point()



ggplot(data, aes_string("`Mi/kWh`")) +
    geom_rect(xmin=oddMin, xmax=oddMax,
              ymin=0, ymax=Inf,fill="#ffffaa") +
    geom_histogram(binwidth=0.2) +
    geom_vline(xintercept=mpkWh, color="red", size=rel(1.5))+
    xlab("Miles per kilowatt-hour") +
    ylab("Number of trips") +
    annotate("label", x = oddMax + 0.2, y=0, hjust=0, vjust=0, fill="#ffffaa",
             size=4,
             label=paste("IQR =", oddMin,"-",oddMax)) +
    annotate("label", x = oddMax + 0.2, y=3, hjust=0, vjust=0, fill="#ffaaaa",
             size=4,
             label=paste("Average =", mpkWh)) +
    scale_x_continuous(sec.axis=sec_axis(~(mpg * cpk/100)/.,
                       name=paste("Break-even gasoline price (presuming",
                           mpg,"mpg and",signif(cpk,3),"cents/kWh)"))) +
    theme(
        axis.title = element_text(face="bold", size=rel(1.5)),
        axis.text = element_text(face="bold", size=rel(1.5))
        )



ggsave("Mileage.png", dpi=75, width=8, height=4)



## Stitch together the Markdown report
head <- readLines("head.md")
tail <- readLines("tail.md")
cat(head, "```", paste(msg, collapse=''), "```", tail,
    file="README.md", sep="\n")

## Generate another month of blank lines for log.txt:
## message(sprintf("%s - - -\n",data$Date[np-1] + 1:30))

