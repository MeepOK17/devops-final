#!/bin/sh
# пароль от vault берется из переменной окружения, в ci это секрет окружения production
printf '%s\n' "$ANSIBLE_VAULT_PASSWORD"
