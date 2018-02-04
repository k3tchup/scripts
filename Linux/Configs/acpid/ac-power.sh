#!/bin/sh

#test -f /usr/share/acpi-support/key-constants || exit 0

# Adjust brightness of backlights based on power source

case $4 in
    # On battery
    00000000)
        # Dim keyboard backlight
        echo 0 > /sys/class/leds/asus::kbd_backlight/brightness
        # Dim screen backlight
        expr `cat /sys/class/backlight/intel_backlight/max_brightness` / 3 > \
            /sys/class/backlight/intel_backlight/brightness
	logger "acpid: dimming the brightness while on battery"
    ;;

    # On AC
    00000001)
        # Dim keyboard backlight
        cat /sys/class/leds/asus::kbd_backlight/max_brightness > \
            /sys/class/leds/asus::kbd_backlight/brightness
        # Dim screen backlight
        cat /sys/class/backlight/intel_backlight/max_brightness > \
            /sys/class/backlight/intel_backlight/brightness
	logger "acpid: on ac-power, raising brightness"
    ;;

    #Something else
    *)
	logger "acpid: unknown ac-power state $1 $2 $3 $4"
esac

