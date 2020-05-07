# Instrucciones de verificación:
1. Copiar los archivos y directorios en una carpeta local.
2. Abrir PowerShell e ingresar la instrucción: 
aws configure
3. Ingresar el AWSAccessKeyId y AWSSecretKey para conectarse a la consolda de aws.
3. Una vez conectado, desde la consola de PowerShell y en la misma ubicación local donde se encuentran los archivos.ejecutar la instrucción:
terraform init 
4. Ejecutar el Plan con la siguiente instrucción:
terraform plan -var-file=".\tfvars.json".

# Asunciones:
* Se asume que se tiene instalados las herramientas PowerShell, aws CLI, terraform y Visual Studio Code.
