ssh-keygen -t ed25519 -f ssh_auth_ed25519_key -N ""
mkdir auth-keys
mv ssh_auth_ed25519_key auth-keys/
mv ssh_auth_ed25519_key.pub auth-keys/serviceuser-auth-key.pub
