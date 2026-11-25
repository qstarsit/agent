#!/bin/bash
# Stores the workshop Bedrock API key in oh-my-pi's agent .env (on the
# omp-config volume), which omp reads at startup.
set -euo pipefail

env_file="$HOME/.omp/agent/.env"

read -rsp "Paste your workshop API key: " key
echo
key="${key//[[:space:]]/}"
if [[ -z "$key" ]]; then
    echo "No key entered, nothing changed." >&2
    exit 1
fi

# One-token call, so a mistyped or expired key fails here instead of inside omp.
region="${AWS_REGION:-eu-north-1}"
response="$(mktemp)"
status="$(curl -sS -o "$response" -w '%{http_code}' --max-time 60 \
    -H "Authorization: Bearer ${key}" -H 'Content-Type: application/json' \
    -d '{"messages":[{"role":"user","content":[{"text":"hi"}]}],"inferenceConfig":{"maxTokens":1}}' \
    "https://bedrock-runtime.${region}.amazonaws.com/model/zai.glm-5/converse" || echo 000)"
case "$status" in
    200) echo "Key works." ;;
    000) echo "Could not reach Bedrock to check the key; saving it anyway." >&2 ;;
    *)
        echo "Bedrock rejected this key (HTTP ${status}): $(jq -r '.message // .Message // .' "$response")" >&2
        echo "Check that you pasted the whole key, then run set-key again." >&2
        rm -f "$response"
        exit 1
        ;;
esac
rm -f "$response"

mkdir -p "$(dirname "$env_file")"
touch "$env_file"
chmod 600 "$env_file"
grep -v '^AWS_BEARER_TOKEN_BEDROCK=' "$env_file" > "${env_file}.tmp" || true
echo "AWS_BEARER_TOKEN_BEDROCK=${key}" >> "${env_file}.tmp"
mv "${env_file}.tmp" "$env_file"
chmod 600 "$env_file"

echo "Key saved. Run: omp"
