#!/bin/sh

if [ $# -lt 2 ]; then
  echo ""
  echo " Usage:"
  echo "   BLUE_VALUE=\$1 0-on 1-off"
  echo "   ORANGE_VALUE=\$2 0-on 1-off"
  echo ""
  exit 1
fi

BLUE_VALUE="$1"
ORANGE_VALUE="$2"

BLUE_PIN=188
ORANGE_PIN=187

# PWM_PERIOD=10000 #microseconds

BIOS_YEAR=$(cut -d "/" -f 3 /sys/class/dmi/id/bios_date)
BIOS_MONTH=$(cut -d "/" -f 1 /sys/class/dmi/id/bios_date)
BIOS_DAY=$(cut -d "/" -f 2 /sys/class/dmi/id/bios_date)

MIN_BIOS_DATE=20110729

if ! (echo "$BIOS_YEAR-$BIOS_MONTH-$BIOS_DAY" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') ; then
  echo "Couldn't understand BIOS date"
  echo "BIOS date should be 07/29/2011 or later"
  exit 1
fi

BIOS_DATE=$((BIOS_YEAR*10000+BIOS_MONTH*100+BIOS_DAY))

if [ $((BIOS_DATE < MIN_BIOS_DATE)) -eq 1 ]; then
  echo "BIOS date should be 07/29/2011 or later"
  exit 1
fi

if ! modprobe i2c-piix4; then
  echo "Couldn't insert i2c-piix4 driver"
  exit 1
fi

if ! modprobe gpio-sb8xx; then
  echo "Couldn't insert gpio-sb8xx driver"
  exit 1
fi

if NEWK=$(uname -r |egrep "6.6"); then
   GPIO_CHIP=512
elif NEWK=$(uname -r |egrep "5.15|6.1"); then
   GPIO_CHIP=768
else
   GPIO_CHIP=256
fi

if ! BASE=$(cat "/sys/class/gpio/gpiochip$GPIO_CHIP/base"); then
  echo "Couldn't determine gpio pin base"
  exit 1
fi

BLUE_PIN=$((BASE+BLUE_PIN))
ORANGE_PIN=$((BASE+ORANGE_PIN))

GPIO_BASE_DIR="/sys/class/gpio"

for PIN in $ORANGE_PIN $BLUE_PIN ; do
  GPIOPATH="$GPIO_BASE_DIR/gpio$PIN"

  if [ ! -d "$GPIOPATH" ]; then
    if ! echo "$PIN" > "$GPIO_BASE_DIR/export"; then
      echo "Couldn't export gpio for $PIN"
      exit
    fi
  fi

done

# 
echo "$BLUE_VALUE" > "$GPIO_BASE_DIR/gpio$BLUE_PIN/value"
echo "$ORANGE_VALUE" > "$GPIO_BASE_DIR/gpio$ORANGE_PIN/value"

