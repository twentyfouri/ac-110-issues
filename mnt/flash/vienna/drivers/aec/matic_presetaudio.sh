#!/bin/sh

mount_as_tmpfs /etc/alsa
mount_as_tmpfs /lib
ln -sf $(pwd)/alsa.conf_plug /etc/alsa/alsa.conf
ln -sf $(pwd)/tutuConfigRX /etc/alsa/tutuConfigRX
ln -sf $(pwd)/tutuConfigTX /etc/alsa/tutuConfigTX
ln -sf $(pwd)/libasound_module_pcm_vatics.3.6.0.0.so /etc/alsa/libasound_module_pcm_vatics.so
ln -sf $(pwd)/libasound_module_pcm_vatics.3.6.0.0.so /lib/libasound_module_pcm_vatics.so

