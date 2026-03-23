#!/usr/bin/env python3
"""
dwt.py - Disable While Typing for T2 Mac trackpad on Linux/Wayland
Directly grabs the touchpad evdev device while keyboard activity is
detected, suppressing all input at the kernel level.
"""
import asyncio
import logging
import evdev

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

DWT_TIMEOUT = 0.8  # seconds of silence before re-enabling trackpad


def find_devices():
    keyboard = None
    touchpad = None
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
        except Exception:
            continue
        if "Apple Internal Keyboard / Trackpad" not in dev.name:
            continue
        caps = dev.capabilities()
        if evdev.ecodes.EV_ABS in caps:
            touchpad = dev
            logging.info(f"Touchpad: {dev.name} @ {dev.path}")
        elif evdev.ecodes.EV_KEY in caps:
            keyboard = dev
            logging.info(f"Keyboard: {dev.name} @ {dev.path}")
    return keyboard, touchpad


async def run():
    keyboard, touchpad = find_devices()
    if not keyboard or not touchpad:
        logging.error("Could not find keyboard or touchpad — check device names")
        return

    grabbed = False
    grab_task = None

    async def release():
        nonlocal grabbed
        await asyncio.sleep(DWT_TIMEOUT)
        if grabbed:
            try:
                touchpad.ungrab()
                grabbed = False
            except Exception:
                pass

    async for event in keyboard.async_read_loop():
        if event.type == evdev.ecodes.EV_KEY:
            if grab_task:
                grab_task.cancel()
            if not grabbed:
                try:
                    touchpad.grab()
                    grabbed = True
                except Exception as e:
                    logging.warning(f"Grab failed: {e}")
            grab_task = asyncio.create_task(release())


asyncio.run(run())
