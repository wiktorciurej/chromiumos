#!/bin/sh
# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Checks for a device specific configuration and if present, starts
# bluetoothd with that config file; otherwise, starts bluetoothd with
# the legacy board-specific configuration (main.conf) if the config file
# is present.

config_file_param=""
bluetooth_dir="/etc/bluetooth"
model_dir="${bluetooth_dir}/models"
legacy_conf_file="${bluetooth_dir}/main.conf"

# TODO(shapiroc): Remove once all config migrated to cros_config
if [ -d ${model_dir} ]; then
  # Note: the below usage of the model name is not a good pattern, but should
  # apply to non-unibuild only as the below bluetooth config will override it.
  model="$(cros_config / name)"
  model_conf_file="${model_dir}/${model}.conf"
  if [ -e ${model_conf_file} ]; then
    config_file_param="--configfile=${model_conf_file}"
  fi
fi

device_config_file="$(cros_config /bluetooth/config system-path)"
if [ -z "${config_file_param}" ] && [ -e "${device_config_file}" ]; then
  config_file_param="--configfile=${device_config_file}"
fi

# If the model specific configuration is not present, check for the
# legacy board-specific configuration
if [ -z "${config_file_param}" ] && [ -e "${legacy_conf_file}" ]; then
  config_file_param="--configfile=${legacy_conf_file}"
fi
exec /sbin/minijail0 -u bluetooth -g bluetooth -G \
  -c 3500 -n -- \
  /usr/libexec/bluetooth/bluetoothd ${BLUETOOTH_DAEMON_OPTION} --nodetach \
  ${config_file_param}
