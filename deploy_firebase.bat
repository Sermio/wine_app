@echo off
echo Construyendo aplicación para web...
flutter build web --release

echo Desplegando a Firebase Hosting...
firebase deploy --only hosting

echo Despliegue completado!
pause











