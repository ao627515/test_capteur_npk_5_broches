# Test Capteur NPK Multi-Paramètres

Application Flutter pour la lecture et l'affichage des données d'un capteur NPK multi-paramètres via connexion USB. Cette application permet de surveiller en temps réel les paramètres essentiels du sol, incluant l'azote (N), le phosphore (P), et le potassium (K), ainsi que d'autres paramètres environnementaux.

## 🌟 Fonctionnalités

- 📊 Lecture en temps réel des paramètres du sol :
  - Température (°C)
  - Humidité (%)
  - Conductivité (µS/cm)
  - pH
  - Azote (N) (mg/kg)
  - Phosphore (P) (mg/kg)
  - Potassium (K) (mg/kg)
  - Indice de fertilité global
- 🔌 Gestion automatique des connexions USB
- ⏱️ Polling automatique configurable
- 📝 Système de journalisation détaillé
- 🔄 Mode de lecture manuelle disponible

## 🏗️ Architecture

Le projet est structuré en trois composants principaux :

### 📱 Interface Utilisateur (`main.dart`)

- Application Flutter avec interface graphique intuitive
- Affichage en temps réel des données du capteur
- Gestion des connexions USB
- Visualisation des logs système

### 📦 Modèles (`models/npk_data.dart`)

- Classe `NPKData` pour l'encapsulation des données du capteur
- Formatage automatique des valeurs avec unités
- Horodatage automatique des mesures

### ⚙️ Services

#### Service NPK (`services/npk_service.dart`)

- Implémentation du protocole Modbus RTU
- Gestion des requêtes et réponses
- Traitement et validation des données
- Calcul CRC16 pour la vérification d'intégrité

#### Service USB (`services/usb_service.dart`)

- Interface avec le matériel USB
- Gestion des événements de connexion/déconnexion
- Configuration du port série (baudrate, bits de données, etc.)
- Gestion du buffer de réception

## 🛠️ Protocol de Communication

L'application utilise le protocole Modbus RTU pour communiquer avec le capteur :

- Adresse esclave : 0x01
- Fonction : 0x03 (Read Holding Registers)
- Registres surveillés : 7-8 registres
- Vérification CRC16 intégrée

## 🚀 Comment Utiliser

1. Lancez l'application
2. Connectez le capteur NPK via USB
3. Sélectionnez le périphérique dans la liste déroulante
4. Les données seront automatiquement actualisées toutes les 3 secondes
5. Utilisez le bouton "Lire maintenant" pour une lecture manuelle

## 🔧 Configuration

- Baudrate par défaut : 9600
- Configuration série : 8 bits de données, 1 bit de stop, pas de parité
- Intervalle de polling : 3 secondes (configurable)

## 👥 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

- Signaler des bugs
- Proposer des améliorations
- Soumettre des pull requests

## 📝 Licence

Projet sous licence [MIT]

---

## À Propos

Développé dans le cadre du projet SmartAgriChange
