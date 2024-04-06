# Docker-Acestream-Linux

Este proyecto proporciona un Dockerfile para crear una imagen Docker que ejecuta Acestream en un contenedor, utilizando BusyBox para la descarga y configuración inicial, y Python Slim como imagen base. Está diseñado para ser ligero, eficiente y fácil de configurar.

## Requisitos Previos

Para usar este Dockerfile, necesitarás tener Docker instalado en tu sistema. Si no tienes Docker, puedes encontrar las instrucciones de instalación en la [documentación oficial de Docker](https://docs.docker.com/get-docker/).

## Construcción de la Imagen

Para construir la imagen Docker a partir de este Dockerfile, ejecuta el siguiente comando en la terminal desde el directorio donde se encuentra el Dockerfile:

```bash
docker build -t docker-acestream-linux .
```

Este comando construye una nueva imagen Docker llamada docker-acestream-linux utilizando el Dockerfile en tu directorio actual.

## Ejecución del Contenedor

Una vez construida la imagen, puedes ejecutar Acestream en un contenedor Docker usando:

```bash
docker run --name acestream -d -p 6878:6878 docker-acestream-linux
```

Este comando inicia un contenedor basado en la imagen docker-acestream-linux, expone el puerto 6878 para acceder a Acestream, y lo ejecuta en modo desacoplado.

## Uso de Acestream

Con Acestream ejecutándose en el contenedor, puedes acceder a él a través del puerto 6878 en la dirección IP de tu máquina Docker. La forma específica de usar Acestream dependerá de tus necesidades particulares.

## Contribuciones
Las contribuciones a este proyecto son bienvenidas. Si deseas contribuir, por favor, haz un fork del repositorio, realiza tus cambios y envía un pull request.

## Licencia
Este proyecto está licenciado bajo la MIT License - ve el archivo [LICENSE](LICENSE.md) para más detalles.
