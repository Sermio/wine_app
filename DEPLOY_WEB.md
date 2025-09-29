# Despliegue de Wine App en Firebase Hosting

## Requisitos previos

1. **Flutter SDK** instalado y configurado
2. **Firebase CLI** instalado:
   ```bash
   npm install -g firebase-tools
   ```
3. **Autenticación en Firebase**:
   ```bash
   firebase login
   ```

## Pasos para desplegar

### Opción 1: Usar scripts automáticos

#### En Windows:

```bash
deploy_firebase.bat
```

#### En macOS/Linux:

```bash
chmod +x deploy_firebase.sh
./deploy_firebase.sh
```

### Opción 2: Pasos manuales

1. **Construir la aplicación para web**:

   ```bash
   flutter build web --release
   ```

2. **Desplegar a Firebase Hosting**:
   ```bash
   firebase deploy --only hosting
   ```

## Configuración

- **Proyecto Firebase**: `wineapp-e5339`
- **Directorio de build**: `build/web`
- **URL de la aplicación**: Se mostrará después del despliegue

## Características de la versión web

- ✅ Compatible con navegadores modernos
- ✅ Funciona en dispositivos móviles (iOS/Android) a través del navegador
- ✅ Selección de imágenes desde archivos (no cámara en web)
- ✅ Autenticación con Firebase Auth
- ✅ Almacenamiento en Firestore
- ✅ Subida de imágenes a Firebase Storage

## Solución de problemas

### Error de permisos

Si tienes problemas con permisos, ejecuta:

```bash
firebase login --reauth
```

### Error de build

Si el build falla, limpia el proyecto:

```bash
flutter clean
flutter pub get
flutter build web --release
```

### Error de hosting

Verifica que Firebase Hosting esté habilitado en tu proyecto:

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto `wineapp-e5339`
3. Ve a "Hosting" en el menú lateral
4. Si no está habilitado, haz clic en "Get started"

## Acceso a la aplicación

Una vez desplegada, la aplicación estará disponible en:

- URL principal: `https://wineapp-e5339.web.app`
- URL alternativa: `https://wineapp-e5339.firebaseapp.com`

Los usuarios de iOS pueden acceder a la aplicación a través del navegador Safari o cualquier otro navegador web.




