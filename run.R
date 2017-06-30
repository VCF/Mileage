file <- "log.txt"

data <- read.delim(file, sep=' ', na.strings=c('-'),
                   comment.char = c('#'), flush=TRUE)

## Ignore last datapoint if it lacks recharge information:
data <- data[ !is.na(data$kWh), ]
np   <- nrow(data)

## Offset structure to calculate deltas; it lacks the last row
offset <- data.frame(Oddometer = c(data$Oddometer[ -np ]),
                     kWh       = c(data$kWh[ -np ]))
## To make offsets work, remove the first row of data
data <- data[ -1, ]

for (col in colnames(offset)) {
    ## Oddometer and watt meter might get reset. If the offset is less
    ## than the data, presume offset to be zero.
    offset[[col]] <- ifelse(offset[[col]] < data[[col]], offset[[col]], 0)
}

## Remove ICE miles from mileage:
offset$Oddometer <- ifelse(is.na(data$MilesICE), offset$Oddometer,
                           offset$Oddometer + data$MilesICE)

## Format date column
data$Date <- as.Date(data$Date, "%Y-%m-%d")

## Calculate per-trip values:
data$MilesEMV    <- data$Oddometer - offset$Oddometer
data$Consumed    <- data$kWh - offset$kWh
data[['Mi/kWh']] <- data$MilesEMV / data$Consumed

## Calculate totals:
milesICE <- sum(data$MilesICE, na.rm=TRUE)
milesEMV <- sum(data$MilesEMV, na.rm=TRUE)
totalkWh <- sum(data$Consumed, na.rm=TRUE)
mpkWh    <- milesEMV / totalkWh
days     <- data$Date[np-1] - data$Date[1]

## Display summary stats:
msg <- sprintf("Summary statistics:
       Time : %d days (%.2f years)
  EMV miles : %.1f
  ICE miles : %.1f
        kWh : %.2f
     Mi/kWh : %.2f
", days, days / 365, milesEMV, milesICE, totalkWh, mpkWh)

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
  BreakEven : $%.2f = Break-even cost of gasoline
", cost, yearly, elecGal))
}

head <- readLines("head.md")

cat(head, "```", msg, "```", file="README.md", sep="\n")

message(msg)
