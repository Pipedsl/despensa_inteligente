🛠 Guía de Configuración: DespensaInteligente¡Bienvenido/a al proyecto DespensaInteligente! Este documento detalla los pasos necesarios para configurar tu ambiente de desarrollo (DEV) y poner a correr la aplicación móvil (Flutter) en un emulador o dispositivo físico.1. Requisitos Previos (Stack Tecnológico Base)Asegúrate de tener instalados y configurados los siguientes componentes:1.1. Herramientas de DesarrolloGit: Sistema de control de versiones.Flutter SDK: Versión 3.22.x o superior. Ejecuta flutter doctor para verificar dependencias de Android/iOS.IDE (Recomendado): VS Code con las extensiones de Flutter y Dart, o Android Studio.Node.js y npm: Necesario para la instalación de Firebase Tools.1.2. Herramientas de GoogleFirebase CLI: Necesario para interactuar con nuestro proyecto de Firebase (Autenticación, BBDD).npm install -g firebase-tools
2. Configuración del RepositorioUtilizaremos un flujo simplificado de GitFlow, donde main es la rama de producción y develop es nuestra rama de integración constante.2.1. Clonar el Repositorio# Clona el repositorio
git clone [https://github.com/Pipedsl/despensa_inteligente.git](https://github.com/Pipedsl/despensa_inteligente.git)
cd despensa_inteligente

# Asegúrate de estar en la rama de desarrollo
git checkout develop
2.2. Instalar Dependencias de FlutterEjecuta este comando para descargar todos los paquetes definidos en pubspec.yaml (Firebase, Riverpod, flutter_dotenv, etc.).flutter pub get
3. Manejo de Credenciales Sensibles (.env) 🚨IMPORTANTE: Por seguridad, las claves de servicios (OpenAI / Genkit API Key, credenciales de usuario de prueba) no se suben al repositorio. Debes crear un archivo local que Git ignora.3.1. Creación del Archivo .envCrea un archivo llamado .env en la raíz del proyecto.touch .env
3.2. Contenido del Archivo .envEl archivo debe tener la siguiente estructura (los valores son solo ejemplos/placeholders, reemplázalos por las claves reales):# .env - NO SUBIR A GIT

# Clave para la integración de IA (Genkit/OpenAI, etc.)
OPENAI_API_KEY="sk-TU-CLAVE-SECRETA-DE-OPENAI-O-GEMINI" 

# Credenciales para el inicio de sesión del usuario de prueba
FIREBASE_TEST_EMAIL="test@despensa.cl"
FIREBASE_TEST_PASSWORD="PasswordDeTestSegura123"

# Otras claves API que podamos necesitar más adelante
# OPENFOODFACTS_API_KEY="" 
3.3. Solicitud de ClavesUna vez que tengas el archivo .env listo, solicita los valores reales de las claves API y credenciales de prueba al Tech Lead (Felipe).Contacto para claves sensibles: felipenavarrete.ps3@gmail.com4. Configuración de FirebaseYa hemos inicializado Firebase en el proyecto y generado el archivo lib/firebase_options.dart a través de la CLI de FlutterFire. Este archivo ya contiene las claves públicas que Flutter necesita para conectarse a nuestro proyecto de Firebase.4.1. Verificación del ProyectoEl archivo firebase_options.dart es generado automáticamente y se ve correctamente. No es necesario modificarlo, pero es útil saber que el projectId es: despensa-inteligente-c1f9d.No necesitas pasos adicionales aquí, solo asegúrate de que el archivo exista.4.2. Log in a Firebase (Opcional)Si necesitas desplegar a Firebase Hosting o usar Firebase Emulators:firebase login
5. Correr la AplicaciónUna vez completados los pasos anteriores, puedes iniciar la aplicación en tu entorno de desarrollo.Abre un simulador de iOS o un emulador de Android.Ejecuta el comando en la raíz del proyecto:flutter run
¡Listo! Si la configuración fue exitosa, deberías ver la pantalla de splash de Flutter y luego la pantalla de Login/Registro.