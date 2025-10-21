```markdown
# Salesforce ToolKit

![Logo](https://raw.githubusercontent.com/slorenzot/SalesforceToolKit/refs/heads/main/images/logo.png)

![Salesforce ToolKit](https://raw.githubusercontent.com/slorenzot/SalesforceToolKit/refs/heads/main/images/splash.png)

Una práctica aplicación para macOS que reside en la barra de menú, diseñada para simplificar y acelerar tus interacciones diarias con Salesforce.

## Videos en Youtube

[![Watch the video](https://i9.ytimg.com/vi/NFUTBLfhFT4/mq2.jpg?sqp=CLCTv8cG-oaymwEmCMACELQB8quKqQMa8AEB-AH-CYAC0AWKAgwIABABGGUgZShlMA8=&rs=AOn4CLBwShry8m2--41O1mAH5xsQ35zztQ)](https://youtu.be/NFUTBLfhFT4)

## Descripción

Salesforce ToolKit te da acceso inmediato a tus organizaciones, herramientas y recursos de Salesforce desde la barra de menú de macOS. Está pensada para administradores, desarrolladores y equipos DevOps que necesitan acceder rápido a orgs, ejecutar comandos de CLI y abrir utilidades frecuentes sin perder tiempo.

## Últimas funciones (Actualizado)

- Gestión mejorada de organizaciones:
  - Soporte para marcar organizaciones como Favoritas y establecer una organización por defecto.
  - Distinción clara entre entornos Production, Sandbox y Scratch Orgs.
  - Visualización de detalles de sesión (usuario conectado, alias, expiración de token).
  - Cierre de sesión y eliminación segura de credenciales almacenadas.
- Métodos de autenticación ampliados:
  - Soporte para OAuth via navegador (auth:web), Device Flow y JWT según configuración de Salesforce CLI.
  - Flujo guiado de autenticación para añadir una nueva org.
- Integración profunda con Salesforce CLI (sfdx / sf):
  - Actualizar la Salesforce CLI desde la aplicación con un clic.
  - Ejecutar comandos comunes de CLI directamente desde menús (por ejemplo, abrir org, ejecutar anonymous Apex, desplegar).
  - Detección automática de la presencia de la CLI y aviso si falta o está desactualizada.
- Enlaces rápidos y personalizables:
  - Categorías predefinidas: Request new org, Tools, DevOp Tools, Help.
  - Añade, edita y organiza tus propios enlaces personalizados.
  - Abre enlaces con el navegador predeterminado o con un navegador específico por enlace.
- Preferencias y personalización:
  - Opción "Abrir al iniciar sesión" (inicio automático).
  - Selección del navegador predeterminado para abrir enlaces.
  - Modo oscuro/tema siguiendo la apariencia de macOS.
  - Configurar atajos de teclado para acciones frecuentes.
- Notificaciones y alertas:
  - Notificaciones sobre actualizaciones de la aplicación o del CLI.
  - Alertas configurables para eventos importantes de tus orgs.
- Exportar / importar configuración:
  - Exporta tus orgs, enlaces y preferencias a un archivo (JSON) para compartir o migrar.
  - Importa configuraciones desde un archivo exportado.
- Salud de la org y diagnósticos:
  - Ejecuta comprobaciones básicas de estado (autenticación, versiones CLI, espacio disponible).
  - Recomendaciones y enlaces rápidos para solucionar problemas.
- Seguridad y privacidad:
  - Almacenamiento seguro de credenciales siguiendo buenas prácticas de macOS.
  - Opción opt-in para telemetría anónima (ayuda a mejorar la app).
- Accesibilidad y localización:
  - Interfaz en español e inglés (otras traducciones en desarrollo).
  - Mejoras en navegación por teclado y compatibilidad con VoiceOver.

## Características Principales (resumen)

- Gestión de múltiples organizaciones Salesforce (favoritos, default, sandbox/prod).
- Acceso instantáneo y organizado a enlaces, herramientas y recursos.
- Integración con Salesforce CLI: actualizar, detectar y ejecutar comandos.
- Personalización del navegador y preferencias de la aplicación.
- Inicio automático, notificaciones y comprobaciones de salud de la org.
- Exportación/importación de configuraciones.
- Seguridad de credenciales y opciones de privacidad.

## Capturas de Pantalla

![Captura 1](https://raw.githubusercontent.com/slorenzot/SalesforceToolKit/refs/heads/main/images/splash.png)
![Captura 2](https://raw.githubusercontent.com/slorenzot/SalesforceToolKit/refs/heads/main/images/image1.png)
![Captura 3](https://raw.githubusercontent.com/slorenzot/SalesforceToolKit/refs/heads/main/images/image2.png)

## Instalación

1. **Descarga**: Ve a la sección [Releases](https://github.com/slorenzot/SalesforceToolKit/releases) y descarga el archivo `.dmg` o `.zip` de la última versión.
2. **Instalación**:
   - Si es un `.dmg`, ábrelo y arrastra la aplicación "Salesforce ToolKit" a la carpeta Aplicaciones.
   - Si es un `.zip`, descomprímelo y arrastra la aplicación a la carpeta Aplicaciones.
3. **Requisitos**: Asegúrate de tener la [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) instalada para que todas las funciones relacionadas con CLI funcionen correctamente. La aplicación detectará si falta la CLI y te ofrecerá instrucciones para instalarla.

## Uso

Una vez instalada, Salesforce ToolKit aparecerá como un icono en la barra de menú superior. Haz clic en el icono para abrir el menú principal.

- **Autenticar nueva organización**: Usa la opción correspondiente para añadir nuevas credenciales de Salesforce (soporta varios flujos de autenticación).
- **Organizaciones autenticadas**: Desde el menú verás las orgs guardadas; abre, edita, desconecta o elimina entradas.
- **Favoritas**: Tus orgs marcadas como favoritas aparecen en una sección separada.
- **Enlaces Rápidos**: Accede a Request new org, Tools, DevOp Tools y Help o a tus enlaces personalizados.
- **Actualizar Salesforce CLI**: Botón para actualizar la CLI desde la app (si procede).
- **Preferencias**: Ajusta el inicio automático, el navegador por defecto, el tema y la telemetría.
- **Exportar / Importar**: Exporta un backup de tu configuración o importa desde otro equipo.

Consejo rápido: mantén marcadas tus orgs de uso frecuente como Favoritas para acceder aún más rápido.

## Contribución

¡Las contribuciones son bienvenidas! Si deseas mejorar Salesforce ToolKit:

1. Haz fork de este repositorio.
2. Crea una rama nueva (`git checkout -b feature/nueva-caracteristica`).
3. Realiza tus cambios y commitea (`git commit -am "Agrega nueva característica"`).
4. Sube tu rama (`git push origin feature/nueva-caracteristica`).
5. Abre un Pull Request describiendo los cambios.

Por favor, añade pruebas y actualiza la documentación cuando corresponda.

## Roadmap / Ideas para próximas versiones

- Más integraciones con herramientas DevOps (CI/CD).
- Autenticación SSO mejorada y plantillas para JWT.
- Más idiomas y mejoras de accesibilidad.
- Widgets o extensiones para integrarse con otras apps de macOS.

## Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

## Contacto

Si tienes dudas, problemas o sugerencias, abre un *issue* en este repositorio o contacta al desarrollador: [slorenzot@github.com](mailto:slorenzot@github.com).
```
