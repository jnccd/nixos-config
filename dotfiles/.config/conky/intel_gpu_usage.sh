#!/usr/bin/env bash
echo "{$(timeout 0.2s intel_gpu_top -J 2>/dev/null | cut -c2-)}" | jq -r '.engines["Render/3D"].busy'