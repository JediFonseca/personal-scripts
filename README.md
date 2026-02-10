## Scripts pessoais.

### Instruções:

1. Colar os scripts em "~/.local/bin/".
2. Se for a primeira vez que scripts estão sendo utilizados nessa pasta, reiniciar o sistema pode ser necessário.

### Atualizar a variável de ambiente $PATH:

Se mesmo após ter reiniciado o sistema os scripts não estiverem funcionando, siga os passos abaixo:

**1. Abra o arquivo .bashrc:**

```
nano ~/.bashrc
```

**2. Vá até o final do arquivo e adicione estas linhas:**

```
# Adiciona a pasta bin local ao PATH
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
```

**3. Salve e saia:**  
Pressione Ctrl + O para salvar, Enter para confirmar e Ctrl + X para sair.

**4. Atualize o terminal atual:**

```
source ~/.bashrc
```

**5. Se necessário, reinicie o terminal.**
