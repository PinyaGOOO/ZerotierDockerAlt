#!/bin/sh
set -eu

fail() {
  printf 'Ошибка: %s\n' "$1" >&2
  exit 1
}

if [ "$(id -u)" -ne 0 ]; then
  fail "нужны права root. Запустите: sudo sh install.sh (или su -c 'sh install.sh')"
fi

if [ ! -r /etc/os-release ] || ! grep -qi '^ID=altlinux' /etc/os-release; then
  fail "этот установщик предназначен для ALT Linux"
fi

command -v apt-get >/dev/null 2>&1 || fail "не найдена команда apt-get"

cd "$(dirname "$0")"

if [ ! -c /dev/net/tun ]; then
  modprobe tun 2>/dev/null || true
fi
[ -c /dev/net/tun ] || fail "нет /dev/net/tun; проверьте поддержку TUN в ядре и настройках виртуальной машины"

printf 'Network ID сети ZeroTier (16 шестнадцатеричных символов): '
IFS= read -r NETWORK_ID
case "$NETWORK_ID" in
  *[!0123456789abcdefABCDEF]*|'') fail "Network ID должен содержать только символы 0-9 и a-f" ;;
esac
[ "${#NETWORK_ID}" -eq 16 ] || fail "Network ID должен состоять ровно из 16 символов"

printf '\nУстанавливаю Docker из репозиториев ALT...\n'
apt-get update
apt-get install -y docker-engine docker-compose
systemctl enable --now docker
docker info >/dev/null 2>&1 || fail "Docker Engine не отвечает; проверьте: systemctl status docker"

if docker compose version >/dev/null 2>&1; then
  compose() { docker compose "$@"; }
elif command -v docker-compose >/dev/null 2>&1; then
  compose() { docker-compose "$@"; }
else
  fail "не найдена команда Docker Compose после установки пакета docker-compose"
fi

printf '\nЗапускаю контейнер ZeroTier...\n'
compose up -d
READY=0
for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  if compose exec -T zerotier zerotier-cli info >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done
[ "$READY" -eq 1 ] || fail "ZeroTier не запустился; проверьте логи командой docker compose logs zerotier"

printf 'Подключаюсь к сети %s...\n' "$NETWORK_ID"
compose exec -T zerotier zerotier-cli join "$NETWORK_ID" || fail "join не выполнен; проверьте логи контейнера"

printf '\nСостояние узла:\n'
compose exec -T zerotier zerotier-cli info
compose exec -T zerotier zerotier-cli listnetworks
printf '\nГотово. В ZeroTier Central включите Authorized для нового участника.\n'
printf 'Контейнер запускается автоматически после перезагрузки; identity хранится в Docker volume zerotier-data.\n'
