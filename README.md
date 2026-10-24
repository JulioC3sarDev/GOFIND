# 📍 GoFind

<div align="center">

<img src="assets/icons/icon.png" width="120" alt="GoFind Logo">

### **Encontre seus amigos mesmo sem internet.**

Projeto acadêmico desenvolvido em **Flutter** para auxiliar grupos de pessoas a se encontrarem em ambientes com pouca ou nenhuma conexão com a internet, utilizando comunicação **peer-to-peer** entre dispositivos.

---

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-orange)
![License](https://img.shields.io/badge/License-Acadêmico-blue)

</div>

---

# 📖 Sobre o projeto

O **GoFind** nasceu da necessidade de ajudar grupos de amigos e familiares que participam de grandes eventos, como:

- 🎵 Shows
- 🎭 Carnaval
- 🎆 Festivais
- ⚽ Estádios
- 🎡 Parques
- 👥 Eventos com grande concentração de pessoas

Nesses locais é comum ocorrer congestionamento das redes móveis, impossibilitando o envio de mensagens e compartilhamento de localização.

O objetivo do GoFind é permitir que integrantes de um grupo consigam localizar uns aos outros utilizando comunicação local entre dispositivos, sem depender de internet.

---

# ✨ Funcionalidades

- 👤 Cadastro de perfil local
- 👥 Criação de grupos
- 🔑 Entrada em grupos por código
- ✅ Aprovação de novos participantes
- 📡 Comunicação offline
- 📍 Radar de proximidade
- 🧭 Direção aproximada dos integrantes
- 💬 Chat local entre participantes
- 🚨 Função "Estou perdido"
- 📍 Marcação de ponto de encontro
- 📱 Interface moderna desenvolvida em Flutter

---

# 🛠 Tecnologias utilizadas

- Flutter
- Dart
- Nearby Connections API
- Bluetooth
- Bluetooth Low Energy (BLE)
- Wi-Fi Direct
- Hive Database
- Material Design 3

---

# 🏗 Arquitetura

```text
Flutter
     │
     ▼
Interface do usuário
     │
     ▼
Lógica de negócio
     │
     ▼
Nearby Connections
(Bluetooth • BLE • Wi-Fi Direct)
     │
     ▼
Comunicação entre dispositivos
```

---

# 📱 Telas

- Tela de Boas-vindas
- Login
- Cadastro
- Página Inicial
- Criar Grupo
- Entrar em Grupo
- Radar
- Chat
- Perfil
- Configurações

---

# 🚀 Como executar

## Clone o projeto

```bash
git clone https://github.com/SEU_USUARIO/gofind.git
```

Entre na pasta

```bash
cd gofind
```

Instale as dependências

```bash
flutter pub get
```

Execute

```bash
flutter run
```

---

# 📂 Estrutura do projeto

```text
lib/
 ├── core/
 ├── models/
 ├── services/
 ├── screens/
 ├── widgets/
 ├── routes/
 └── main.dart

assets/
 ├── images/
 └── icons/

android/

ios/
```

---

# 🎯 Objetivo acadêmico

Este projeto foi desenvolvido para fins acadêmicos na disciplina de Desenvolvimento Mobile, explorando conceitos como:

- Desenvolvimento multiplataforma
- Comunicação peer-to-peer
- UX/UI
- Persistência local
- Arquitetura Flutter
- Desenvolvimento offline-first

---

# 📸 Interface