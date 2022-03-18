##################################################
# Generates a root, intermediate and client cert
# Requires openssl installed on the host
##################################################

rootCN=root2
intermediateCN=intermediate2
clientCN=client2

##################################################
# Generate root cert
##################################################
echo "Generating root"
# Generate private and public key pair for root cert; output is a pem file (pkcs8 format)
openssl genrsa -out $rootCN.key 2048

# Generate self signed root certificate (no need for a CSR...no one to sign it)
openssl req -new -x509 -days 1826 -key $rootCN.key -out $rootCN.cer -subj /CN=$rootCN

##################################################
# Generate intermediate cert
##################################################
echo "Generating intermediate"
# Generate private and public key pair for intermediate cert; output is a pem file (pkcs8 format)
openssl genrsa -out $intermediateCN.key 2048

# Generate CSR for intermediate
openssl req -new -key $intermediateCN.key -out $intermediateCN.csr -subj /CN=$intermediateCN

# Generate the settings file for the intermediate cert
echo "[ v3_intermediate_ca ]" > "extensions.txt"
echo "subjectKeyIdentifier = hash" >> "extensions.txt"
echo "authorityKeyIdentifier = keyid:always,issuer" >> "extensions.txt"
echo "basicConstraints = critical, CA:true" >> "extensions.txt"
echo "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" >> "extensions.txt"

# Generate intermediate cert signed using root cert
#openssl x509 -req -days 730 -in $intermediateCN.csr -CA $rootCN.cer -CAkey $rootCN.key -set_serial 01 -out $intermediateCN.cer -addext "basicConstraints=critical,CA:TRUE"
openssl x509 -req -days 730 -in $intermediateCN.csr -CA $rootCN.cer -CAkey $rootCN.key -set_serial 01 -out $intermediateCN.cer -extfile extensions.txt -extensions v3_intermediate_ca

##################################################
# Generate client cert
##################################################
echo "Generating client"
# Generate pemkey pair for client cert; output is a pem file (pkcs8 format)
openssl genrsa -out $clientCN.key 2048

# Generate CSR for client cert
openssl req -new -key $clientCN.key -out $clientCN.csr -subj /CN=$clientCN

# Generate cert signed using intermediate cert
openssl x509 -req -days 730 -in $clientCN.csr -CA $intermediateCN.cer -CAkey $intermediateCN.key -set_serial 01 -out $clientCN.cer

# The IoT Hub Device .NET SDK needs both the signed certificate as well as the private key information. 
# It expects to load a single PFX-formatted bundle containing all necessarily information.
# We can combine the key and certificate into a single PFX archive as follows:
echo "Generating pfx"
openssl pkcs12 -export -out $clientCN.pfx -inkey $clientCN.key -in $clientCN.cer -passout pass:

echo
echo "##################################################:"
echo "Files generated:"
echo "root: " $rootCN.cer
echo "root: " $rootCN.key
echo "intermediate: " $intermediateCN.cer
echo "intermediate: " $intermediateCN.key
echo "client: " $clientCN.cer
echo "client: " $clientCN.key
echo "client: " $clientCN.pfx
