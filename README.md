# ZeroTier для ALT Linux через Docker

Репозиторий запускает официальный образ `zerotier/zerotier` в Docker. Настройка рассчитана на ALT Linux с доступными пакетами `docker-engine` и `docker-compose`; подготовлена с учётом ALT Server 11.1 (p11, x86_64). Установка Engine следует [документации ALT](https://docs.altlinux.org/ru-RU/alt-education/11.1/html/alt-education/docker.html), параметры контейнера — [инструкции ZeroTier для Docker](https://docs.zerotier.com/docker/).

Установщик одной командой ставит Docker из репозиториев ALT, включает его при старте системы, запускает контейнер, спрашивает Network ID и подключает узел. ZeroTier identity хранится в Docker volume.

## Установка

Нужны Git, доступ к репозиториям ALT и Docker Hub. Замените URL ниже на адрес вашего репозитория:

```sh
git clone https://git.example.org/ВАША_ГРУППА/zerotier-alt.git
cd zerotier-alt && sudo sh install.sh
```

Если вы уже вошли как `root`, используйте `cd zerotier-alt && sh install.sh`.

Установщик запросит Network ID (16 шестнадцатеричных символов). Создайте сеть в [ZeroTier Central](https://my.zerotier.com/) заранее. После подключения откройте её в Central и включите `Authorized` для нового участника. Это обязательная проверка ZeroTier; без неё узел не получит доступ к сети.

## Проверка и управление

Команды выполняются из каталога репозитория:

```sh
docker compose ps
docker compose exec zerotier zerotier-cli info
docker compose exec zerotier zerotier-cli listnetworks
docker compose logs -f zerotier
```

Если установлена отдельная команда Compose, используйте `docker-compose` вместо `docker compose`.

Перезапуск: `docker compose restart zerotier`.

Обновление образа:

```sh
docker compose pull
docker compose up -d
```

Остановка без удаления identity: `docker compose down`. Не добавляйте `-v`, если хотите сохранить identity. Без volume ZeroTier создаст новый узел при пересоздании контейнера, который потребуется авторизовать заново.

## Сеть и права контейнера

Compose использует сетевой режим хоста, `/dev/net/tun` и Linux capabilities `NET_ADMIN` и `SYS_ADMIN`, чтобы ZeroTier мог создавать виртуальный интерфейс и настраивать маршруты на хосте. Managed routes ZeroTier влияют на таблицу маршрутизации ALT-машины. Перед подключением сети с маршрутами к удалённо администрируемому серверу убедитесь, что доступна консоль гипервизора или локальная консоль.

Входящий UDP-порт 9993 отдельно публиковать не нужно, так как контейнер работает в host network. Нужны исходящий доступ в интернет и доступ к Docker Hub при первой установке и обновлении.

## Устранение неполадок

```sh
systemctl status docker --no-pager
ls -l /dev/net/tun
docker compose logs --tail=100 zerotier
docker compose exec zerotier zerotier-cli info
```

Если нет TUN, проверьте поддержку модуля в ядре и настройки виртуальной машины. Установщик попробует загрузить модуль `tun`, но не сможет включить его, если гипервизор не предоставляет TUN.

## Состав репозитория

- `compose.yaml` — описание контейнера и постоянного Docker volume.
- `install.sh` — установка Docker, запуск контейнера и подключение к сети.
- `README.md` — инструкция.
