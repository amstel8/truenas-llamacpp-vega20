# llama.cpp + ROCm для gfx906 (Docker и TrueNAS)

Сборка [llama.cpp](https://github.com/ggerganov/llama.cpp) с поддержкой AMD GPU **gfx906** (Radeon VII, MI50) на базе ROCm 7.0. Ядра rocBLAS для gfx906 подставляются из пакета ROCm 6.3, так как в 7.0 они не поставляются.

## Содержимое репозитория

| Файл | Описание |
|------|----------|
| `Dockerfile` | Сборка образа: Ubuntu 22.04 + ROCm 7.0 + ядра gfx906 из 6.3 + llama.cpp |
| `llamacpp_app.yaml` | Конфиг приложения для TrueNAS (Docker Compose) |


## Требования

- **GPU:** gfx906 (AMD Radeon VII, Instinct MI50).
- **Хост:** TrueNAS Scale с AMD Radeon VII 16GB (vega 20).
- Для контейнера нужен доступ к `/dev/dri` и `/dev/kfd`.

## Сборка образа

```bash
docker build -t llama-rocm .
```

## Готовый образ

Образ опубликован на Docker Hub:

```bash
docker pull amstel8/llama-rocm:gfx906-rocm7
```

## Запуск контейнера

Минимальный запуск (модель и порт):

```bash
docker run -d --rm \
  --device /dev/dri \
  --device /dev/kfd \
  -p 8080:8080 \
  -v /path/to/models:/models \
  -e HIP_VISIBLE_DEVICES=0 \
  -e HSA_OVERRIDE_GFX_VERSION=9.0.6 \
  amstel8/llama-rocm:gfx906-rocm7 \
  -m /models/your-model.gguf -ngl 999 -c 8192 --host 0.0.0.0 --port 8080
```

Полезные переменные для gfx906:

- `HIP_VISIBLE_DEVICES` — номер GPU (например `0`).
- `HSA_OVERRIDE_GFX_VERSION=9.0.6` — явно указать gfx906 при проблемах с определением.
- `GGML_HIP_FORCE_MMQ=1`, `GGML_HIP_NO_VMM=1`, `GGML_HIP_PINNED_MEM=1` — опционально для стабильности/производительности.

## Развёртывание в TrueNAS

1. В TrueNAS Scale: **Apps** → установить/настроить приложение по Docker Compose.
2. В качестве манифеста использовать `llamacpp_app.yaml`
3. Обязательно:
   - указать образ `amstel8/llama-rocm:gfx906-rocm7`;
   - пробросить устройства `/dev/dri` и `/dev/kfd`;
   - смонтировать том с моделями в каталог `/models` в контейнере.
4. В конфиге задать свою модель в `command` (параметр `-m /models/...gguf`) и при необходимости порт (в yml порт приложения часто 11434 → 8080 в контейнере).

Путь к моделям в примерах — `/mnt/bamboo/smb/ai`. Замените на свой датасет или SMB-шару с `.gguf` файлами.

## Лицензия

llama.cpp — MIT. ROCm — лицензия AMD. Данный репозиторий — только Dockerfile и конфиги для удобной сборки и запуска.
