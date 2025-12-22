# Acestream Dockerizado

[Read documentation in English](README.md)

Este proyecto despliega Acestream dentro de un contenedor Docker usando Ubuntu 22.04 y Python 3.10 para garantizar la
compatibilidad.

Acestream es una plataforma para streaming en vivo a través de redes peer-to-peer. Dockerizar Acestream simplifica su
configuración y proporciona entornos aislados.

## Requisitos Previos

1. **Instalación de Docker**: Asegúrate de que Docker Desktop esté instalado en tu sistema.
   - [Página de productos de Docker](https://www.docker.com/products/docker-desktop)
   - [Documentación Oficial](https://docs.docker.com/get-docker/)

## Instalación Automática y Ejecución con Scripts de Configuración (Windows)

### Selección de Idioma
Elige el script de configuración según tu idioma preferido:

- **🇺🇸 English**: Usa `SetupAcestream.bat`
- **🇪🇸 Español**: Usa `SetupAcestream_es.bat`

Ambos scripts tienen **funcionalidad idéntica** y solo difieren en el idioma de la interfaz.

### Descripción del Script
Los scripts de configuración automatizan las siguientes tareas:

   - Verificación de la instalación y estado operativo de Docker.
   - Descarga de la imagen Docker más reciente de Acestream.
   - Configuración del contenedor con asignación dinámica de puertos (para evitar conflictos).
   - Actualización del archivo `docker-compose.yml` de forma dinámica según los puertos disponibles.
   - Inicio del contenedor Acestream y apertura de la interfaz web.

### Uso
1. **Elige tu idioma**: Descarga `SetupAcestream.bat` (inglés) o `SetupAcestream_es.bat` (español)
2. **Ejecutar como Administrador**: Haz clic derecho en el script elegido y selecciona "Ejecutar como administrador"
3. **Seguir las instrucciones**: El script te guiará a través del proceso de configuración

> **Nota:** El script garantiza que se utilice la imagen Docker más reciente de Acestream y que la gestión del
> contenedor se maneje de manera eficiente.

## Construir la Imagen

Este proyecto utiliza la imagen base **ubuntu:22.04**. Debes clonar el proyecto completo primero. Luego, para construir
la imagen, utiliza:

```bash
docker build --no-cache -t docker-acestream .
```

## Ejecutar el Contenedor

Para iniciar un contenedor y ejecutar Acestream con asignación dinámica de puertos:

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream
```

El script `SetupAcestream.bat` maneja la asignación dinámica de puertos para evitar conflictos al ejecutar múltiples
instancias.

## Docker Compose

### Modo Estándar (Caché en Disco)

1. **Iniciar el Contenedor**: Usa `docker-compose` para iniciar el contenedor:

   ```bash
   docker-compose up -d
    ```

2. **Actualizar la Imagen**: Para obtener la última versión de la imagen:

   ```bash
   docker-compose pull && docker-compose up -d
    ```

### Modo Caché RAM (Solo Linux/WSL2)

Para mejorar el rendimiento y reducir el desgaste del disco, puedes ejecutar Acestream con la caché almacenada en RAM en lugar del disco.

**Requisitos:**
- Sistema Linux o WSL2 (no funciona en Docker Desktop para Windows sin WSL2)
- Al menos 8GB de RAM disponible

**Uso:**

1. **Detener cualquier contenedor en ejecución primero:**

   ```bash
   docker-compose down
   ```

2. **Iniciar en modo caché RAM:**

   ```bash
   docker-compose --profile ram up -d
   ```

   > **Nota:** Docker Compose intentará iniciar tanto el contenedor base (`acestream`) como el contenedor del perfil RAM (`acestream-ram`). El contenedor base fallará al iniciar debido al conflicto de puerto (esto es comportamiento esperado). Solo `acestream-ram` se ejecutará correctamente en el puerto 6878.

3. **Verificar que solo el contenedor RAM está ejecutándose:**

   ```bash
   docker ps --filter "name=acestream" --format "table {{.Names}}\t{{.Status}}"
   ```

   Salida esperada: Solo `acestream-ram` debe estar ejecutándose y saludable (healthy).

4. **Volver al modo estándar:**

   ```bash
   docker-compose down
   docker-compose up -d
   ```

**Monitorizar el uso de RAM:**

```bash
# Verificar uso actual de RAM
docker exec acestream-ram df -h | grep ACEStream

# Monitorización en tiempo real
watch -n 1 "docker exec acestream-ram df -h /root/.ACEStream/.acestream_cache"
```

**Notas Importantes:**
- Solo puede ejecutarse un modo (estándar o RAM) a la vez debido a conflictos de puerto
- Los datos de caché se pierden cuando el contenedor se detiene (este es el comportamiento esperado para caché RAM)
- La caché RAM reduce significativamente las escrituras en disco, prolongando la vida útil de SSDs
- El tamaño de la caché RAM está configurado en 8GB por defecto

### Modo Caché Memoria (Multi-plataforma)

Para usuarios que quieren caché en RAM pero necesitan compatibilidad multi-plataforma, usa el flag nativo de Acestream:

**Uso:**

1. **Detener cualquier contenedor en ejecución primero:**

   ```bash
   docker-compose down
   ```

2. **Iniciar en modo caché memoria:**

   ```bash
   docker-compose --profile memory up -d
   ```

   > **Nota:** Docker Compose intentará iniciar tanto el contenedor base (`acestream`) como el contenedor del perfil memoria (`acestream-memory`). El contenedor base fallará al iniciar debido al conflicto de puerto (esto es comportamiento esperado). Solo `acestream-memory` se ejecutará correctamente en el puerto 6878.

3. **Verificar que el flag está activo:**

   ```bash
   docker logs acestream-memory | grep "Extra Flags"
   ```

   Salida esperada: `Extra Flags: --live-cache-type memory`

**Características:**
- Usa el flag nativo de Acestream `--live-cache-type memory`
- Funciona en Windows, macOS y Linux (a diferencia de tmpfs que requiere Linux/WSL2)
- Acestream gestiona la asignación de memoria automáticamente
- La caché se pierde al detener el contenedor (comportamiento esperado)

**Comparación:**

| Modo | Almacenamiento | Plataforma | Control RAM | Comando |
|------|----------------|------------|-------------|---------|
| Estándar | Disco | Todas | N/A | `docker-compose up -d` |
| RAM (tmpfs) | RAM (8GB) | Linux/WSL2 | Docker | `docker-compose --profile ram up -d` |
| Memory (flag) | RAM (auto) | Todas | Acestream | `docker-compose --profile memory up -d` |

**¿Por qué falla el contenedor base al usar perfiles?**

Cuando ejecutas `docker-compose --profile <perfil> up -d`, Docker Compose inicia tanto el servicio base como el servicio específico del perfil porque los servicios de perfil usan `extends` para heredar configuración. Como ambos intentan vincularse al puerto 6878, el contenedor base falla (esperado), y solo el contenedor del perfil se ejecuta correctamente. Este es el comportamiento normal de Docker Compose y asegura retrocompatibilidad cuando se ejecuta `docker-compose up -d` sin ningún perfil.

## Acceder a la Interfaz Web

Accede a Acestream a través de la interfaz web. El script `SetupAcestream.bat` abre automáticamente la URL correcta
basada en el puerto asignado:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/player/
```

Puedes cargar enlaces de Acestream directamente en el campo de entrada proporcionado.

## Verificar la Salud del Contenedor

Verifica el estado de salud del contenedor de Acestream:

```bash
docker inspect --format='{{json .State.Health}}' docker-acestream
```

Alternativamente, utiliza la interfaz web:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/api/service?method=get_version
```

## Personalización

### Asignación Dinámica de Puertos

El proyecto incluye la asignación dinámica de puertos tanto para HTTP como para HTTPS para evitar conflictos al ejecutar
múltiples instancias. Esto se maneja en el script `SetupAcestream.bat`.

### Configuración de la Interfaz Web

El archivo `player.html` se actualiza dinámicamente con la dirección IP y el puerto correctos durante el proceso de
inicio del contenedor. Esto asegura que la interfaz web apunte a la instancia correcta del motor de Acestream.

## Variables de Entorno

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| INTERNAL_IP | Dirección IP que usan el reproductor y el motor como endpoint anunciado. | 127.0.0.1 |
| HTTP_PORT | Puerto expuesto para tráfico HTTP dentro del contenedor. | 6878 |
| HTTPS_PORT | Puerto expuesto para tráfico HTTPS dentro del contenedor. | 6879 |

## Características Principales

- Scripts de instalación en Windows de un solo clic con descarga automática de la imagen Docker y asignación dinámica de puertos.
- `acestream.conf` preconfigurado con límites de concurrencia y caché adecuados para producción.
- Script de arranque reforzado (`entrypoint.sh`) que valida variables de entorno y muestra diagnósticos detallados.
- Parche automático de `player.html` para que la interfaz web siempre apunte a la IP y puerto correctos.
- Soporte multi-instancia: puedes lanzar varios contenedores simultáneamente sin conflictos de puertos.
- **Monitoreo de salud**: Healthcheck integrado detecta fallos del servicio y permite auto-reinicio.
- **Modos de caché flexibles**: Elige disco, RAM (tmpfs), o memoria (flag nativo) según tu plataforma y necesidades.
- Construcciones offline gracias al archivo `resources/acestream.tar.gz` incluido (no se requieren descargas externas).
- **Detección automática de conflictos de puertos**: si el puerto por defecto `6878` está ocupado (por ejemplo, por Acestream Player de escritorio), el script de Windows asigna el siguiente puerto par libre.
- Flag opcional `--auto-clean`: tras descargar una nueva imagen, el script puede eliminar de forma segura las imágenes antiguas de Acestream para mantener limpio tu host Docker.

## Solución de Problemas y Consejos

- Asegúrate de que los puertos seleccionados por el script de Windows estén **abiertos en tu firewall**.
- Si aparece el mensaje "puerto ya en uso", el script cambiará automáticamente al siguiente puerto libre — verifica el puerto final mostrado en consola.
- Para uso en Linux/macOS establece `INTERNAL_IP`, `HTTP_PORT` y `HTTPS_PORT` al ejecutar `docker run` o `docker-compose`.
- Utiliza `--auto-clean` con el script para eliminar automáticamente imágenes obsoletas de Acestream tras una actualización (o responde *S* cuando se solicite).
- Visualiza los registros en tiempo real con `docker logs -f <nombre_contenedor>` para diagnosticar problemas del motor.
- El motor escribe información de depuración adicional cuando la opción `--log-debug` está habilitada en `acestream.conf`.

## Aviso Legal

Este repositorio solo distribuye scripts de automatización. El binario de Acestream se proporciona para **uso personal, educativo o de investigación**.
Eres el único responsable de garantizar que tu uso cumpla con todas las leyes y regulaciones aplicables.

## Contribuciones

Agradecemos las contribuciones. Haz un fork, realiza cambios y envía un pull request para revisión.

## Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
