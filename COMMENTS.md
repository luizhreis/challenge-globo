# Análise da aplicação

Observando o app de comentários que foi entregue nota-se pelo arquivo `.python-version` que a versão usada é a `3.7.4`. Ainda, o arquivo `requirements.txt` indica os pacotes necessários para a execução.

Em uma breve análise, notei que a aplicação foi desenvolvida usando o framework Flask. Este framework normalmente usa como dependências o Click, para sua interface CLI, o itsdangerous, para dar mais segurança aos tokens e cookies de autenticação, o Jinja2, para renderizar HTML dinamicamente, o MarkupSafe, usado pelo Jinja2 para o tratamento de entrada de dados para evitar ataques como XSS, e o Werkzeug, a lib WSGI usada como base pelo Flask. Por último o gunicorn é um serviço HTTP no padrão WSGI que serve para executar a aplicação de forma mais robusta e confiável em comparação ao Flask.

Também notei que a API de comentários não usa nenhum tipo de banco de dados, armazenando os valores em memória de forma efêmera. Futuramente, uma melhoria seria a inclusão de um banco para a persistência dos dados relacionados. 

Da mesma forma, a API não parece ter nenhum tipo de autenticação. Seria interessante discutir esta possível melhoria em razão de eventuais abusos que possam ser cometidos pelos usuários. 

Por enquanto deixarei estas melhorias para mais tarde e focarei apenas em disponibilizar a API de comentários da forma que foi entregue.

# Execução da aplicação

Embora seja possível executar os serviços de forma direta no host, por uma questão de consistência do ambiente, facilidade e agilidade de criação, além de já se tratar do primeiro estágio de uma esteira de CI/CD, terminando com um artefato rastreável e imutável, optei por executar a aplicação em docker. [Commit bf7cdd94]

O build e run são feitos desta forma

`docker build -t comments-api .`
`docker run -p 8000:8000 -e PORT=8000 -d comments-api:latest` 

Com a API em execução, fiz os testes locais conforme descritos no `README.md` para verificar que tudo funcionava conforme esperado.

# Infraestrutura

Em um contexto real, a infraestrutura é provida em ambiente de nuvem, seja ela pública ou privada, por um serviço IaaS. Adicionalmente, temos a configuração dos recursos através de ferramentas IaC para gerenciar e provisionar estes recursos.

Esta infraestrutura poderia ser, por exemplo, formada por um cluster Kubernetes com pelo menos 3 hosts para prover a aplicação com conceitos de alta disponibilidade. 

O provisionamento desta infraestrutura poderia ser feito por IaC usando Terraform combinado com Terragrunt. Esta escolha é devida a maturidade da ferramenta, sua documentação, a ampla adoção pelo mercado e uma comunidade opensource ativa. 

A escolha pelo kubernetes é pelo fato de que se trata de uma ferramenta que entrega uma vasta gama de recursos, desde a implantação da aplicação até a observabilidade dela, incluindo automação de escalabilidade, atualização e rollback da aplicação.

Para o desafio que me foi proposto, por motivos de custos, limitação do meu equipamento pessoal e simplicidade da solução, optei por fazer uma versão reduzida da infraestrutura onde instancio por script bash um minikube. A escolha pelo bash é exclusiva pelo fato que o minikube é executado em um único host, minha máquina pessoal, por comandos shell, incluindo seus arquivos de configuração `.yml`. Desta forma, usei uma abordadem imperativa de IaC para gerenciar a infra local de forma simples e objetiva.

Para provisionar o minikube basta executar o script `provision-k8s.sh`
Por simplicidade faço o build da imagem sempre que este script é executado. [Commits 62ddc8ed e 0ff64201]

# Pipeline CI/CD

Para a esteira de implantação, um possível fluxo de entrega, desde a faze de desenvolvimento até a implantação, é descrito resumidamente pelas etapas à seguir.

Considero essencial o uso de pelo menos duas branchs `long lived` para melhor separação entre os códigos de desenvolvimento e produção. Além disso, também separa os repositórios de imagens de desenvolvimento e produção. Desta forma, todas a imagens mais recentes que foram publicadas são preservadas inalteradas para que seja possível sua rastreabilidade, análise de segurança de forma separada da aplicação em prod e em eventuais rollbacks.

Sendo assim, as branches são divididas desta forma.

1. **Branch dev**
    É a branch `long lived` de desenvolvimento. Todo trabalho é feito pelo desenvolvedor em uma branch fork à partir dela.
    Sempre que uma modificação occorrer nesta branch, por exemplo um merge de PR, os testes de código são executados, assim como os testes de  cobertura e segurança.
    Se tudo passar, a imagem é construída e enviada para o repositório como uma imagem de dev pronta para ser submetida aos testes de staging.
    Neste ponto os testes de qualidade são aplicados, incluindo testes E2E e performance.
2. **Branch main**
    É a branch `long lived` para o código que entra em produção.
    Com a imagem aprovada nos testes de staging, é feito o merge do código da dev para a main e a imagem que foi construída em dev promovida para prod. Ou seja, a imagem é enviada para o repositório de prod e inicia o processo de atualização.
    Importante notar que, uma vez construída a imagem em dev, ela não é novamente construída mas sim enviada inalterada para o repositório de prod. Isto evita que alterações no processo de build ou no código/dependências cause alterações que não foram validadas pela etapa de staging.

Para a automação desta proposta seria usado o Github Actions uma vez que é uma ferramenta já presente no repositório de código, também de ampla adoção pelo mercado e que possibilita o uso, inclusive, de infraestrutura própria para a execução das tarefas.

Em exemplo de como seria esta pipeline usando o Github Actions pode ser visto no arquivo `example/pipeline.yml`. Entretanto, como estou usando o minikube local e não tenho múltiplos repositórios de imagens, seria muito mais complexo construir esta solução usando o Github Actions. Por isto, novamente user um script bash para simular esta automação. De forma simples simulando a pipeline, sempre que a API for modificada o script `deploy.sh` deve ser executado. Este script simula cada etapa da pipeline com exceção do envio da imagem para os repositórios. [Commit 22b2efd9]

# Monitoramento e métricas

Seguindo a ideia de usar ferramentas opensource optei pelo Prometheus combinado com o Grafana. Uma vantagem é que eles podem ser facilmente integrados com o minikube.

Para isso, foi preciso alterar a API para incluir no código a biblioteca do Prometheus para gerar as métricas no formato correto. Além disso, foi criado um novo endpoint `/metrics` onde o prometheus busca as informações. A requisição abaixo é um exemplo de como isso pode ser feito. [Commit b02d61fc]
`curl -sv localhost:8000/metrics`

Com a API adaptada para fornecer as métricas é necessário incluir no kubernetes o Prometheus e o Grafana. Este trabalho foi iniciado com o commit 2dd10ef6 mas infelizmente não tive tempo para terminar. Ainda ficou faltando automatizar sua configuração e persistência de dados. Também faltou definir melhor as métricas, e dashboard, além de regras para escalamento dos serviços.

Outro ponto que gostaria de ter feito mas não tive tempo é a verificação da saúde da aplicação. Seria necessário colocar endpoints como `/healthcheck` para serem testados e incluir a configuração no kubernetes.

# Melhorias
Abaixo estão alguns pontos que anotei sobre os quais gostaria de ter tido tempo para implementar e não foi possível. 

- app.debug como parametro da imagem
- reduzir tamanho da imagem docker
- hardening imagem docker
- adicionar db ao app
- adicionar auth ao app